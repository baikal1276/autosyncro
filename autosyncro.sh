#!/bin/bash
#                                       ##############
#                                       # AutoSyncro #
#                                       ##############
# Version 1.1.3
#
# Par Baikal276
#
# 30 décembre 2024
#
# Script de sauvegarde avec rsync.
# Dossier distant vers dossier local - dossier local vers dossier distant - dossier local vers dossier local.
# Vérification de l'espace disque disponible avant sauvegarde.
# Vérifiaction du nombre d'éléments modifiés avant sauvegarde, valeur maximum configurable en pourcentage.
# Envoi d'un email en cas d'échec.
#
# Nécessite un fichier de configuration "autosyncro.conf" dans le dossier courant du script
# Editez le fichier de configuaration "autosyncro.conf" pour personnaliser votre sauvegarde
#
# ///// Dépendances sur la machine local: \\\\\
#
# --- rsync (essentiel pour la sauvegarde) ---
# --- ssh-agent préalablement configuré (optionnel) pour la gestion des clés et passphrase si dossier distant défini ---
# https://wiki.archlinux.org/title/SSH_keys
# --- swaks (optionnel) pour l'envoi d'emails en cas d'échec
#
# ///// Dépendances sur le serveur distant: \\\\\
#
# --- rsync (essentiel pour la sauvegarde) ---
#
#
# ##################### CODE ######################
#
# Fichier de configuration pour la déclaration des variables
#
source ./autosyncro.conf
#
# Déclaration des variables de code couleur
#
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
#
# Logs
#
touch $LOG_FILE > /dev/null 2>&1
if [[ $? = 0 ]]; then
    exec > >(tee ${LOG_FILE}) 2>&1
else
    echo -e "${RED}Impossible de créer le fichier de log, vérifier le chemin et les permissions${ENDCOLOR}"
    exit 2
fi
#
########## Fonctions ##########
#
### Fonctions d'alertes ###
#
# Envoi d'un email en cas d'échec
#
warning_mail()
{
if [[ $MAILTO =~ "@" ]]; then
    echo "La sauvegarde à échouée, voir $LOG_FILE"
    swaks -t $MAILTO -s $ASMTP:$PSMTP -tls -au $USMTP -ap $PASSMTP -f $MAILFROM --body "Echec lors de la sauvegarde" --h-Subject "AutoSyncro" --attach $LOG_FILE >> $LOG_FILE
else
    echo -e "${RED}La sauvegarde à échouée, voir $LOG_FILE${ENDCOLOR}"
fi
}
#
# Vérification de la bonne execution des commandes
#
check_cmd()
{
if [[ $? -eq 0 ]]; then
    	echo -e "${GREEN}OK${ENDCOLOR}"
else
    	echo -e "${RED}ERREUR${ENDCOLOR}"
        warning_mail
fi
}
#
#
# Fonction de vérification de la présence du programme rsync en local
#
check_rsync ()
{
if [[ ! -x "/usr/bin/rsync" ]]; then
    echo -e "${RED}rsync n'est pas installé sur votre système. Arrêt du programme${ENDCOLOR}"
    warning_mail
    exit 2
fi
}
#
# Fonction de vérification de la présence du programme rsync sur le server distant
#
check_rsync_dist ()
{
ssh -p "$PORT" "$SERVER" 'bash -s' <<ENDSSH
    if [[ ! -x /usr/bin/rsync ]]; then
        echo -e "${RED}rsync n'est pas installé sur le serveur distant${ENDCOLOR}"
        warning_mail
        exit 2
    fi
ENDSSH
}
#
### Fonctions de vérifications des cibles sources, destinations et serveurs ###
#
check_dir_fromdist ()
{
# Isolation des valeurs relatives au serveur, au dossier source et à l'utilisateur
declare -r SERVER=$(echo $SOURCE | cut -d ':' -f1 | cut -d '@' -f2)
declare -r DIRECT=$(echo $SOURCE | cut -d ':' -f2)
declare -r SSHUSER=$(echo $SOURCE | cut -d ':' -f1 | cut -d '@' -f1)
# Vérification de la disponibilité du serveur
ping -c 2 $SERVER >> $LOG_FILE
if [[ $? != 0 ]]; then 
    echo -e "${RED}Le serveur $SERVER est injoignable${ENDCOLOR}"
    warning_mail
    exit 112
else
    echo -e "${GREEN}Le serveur $SERVER répond${ENDCOLOR}"
fi
# Vérification de la présence du dossier source distant
ssh -p $PORT "$SSHUSER@$SERVER" "ls $DIRECT > /dev/null 2>&1" > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo -e "${RED}Le dossier $DIRECT n'existe pas sur $SERVER ou est inaccessible par $SSHUSER${ENDCOLOR}"
    warning_mail
    exit 2
fi
# Vérification de la présence du dossier de destination local et des permissions en écriture
if [[ ! -d "$DESTINATION" || ! -w "$DESTINATION" ]]; then
    echo -e "${RED}Le dossier $DESTINATION n'existe pas ou n'est pas accessible en écriture${ENDCOLOR}"
    warning_mail
    exit 2
fi
}
#
check_dir_todist ()
{
# Isolation des valeurs relatives au serveur, au dossier de destination et à l'utilisateur
declare -r SERVER=$(echo $DESTINATION | cut -d ':' -f1 | cut -d '@' -f2)
declare -r DIRECT=$(echo $DESTINATION | cut -d ':' -f2)
declare -r SSHUSER=$(echo $DESTINATION | cut -d ':' -f1 | cut -d '@' -f1)
# Vérification de la disponibilité du serveur
ping -c 2 $SERVER >> $LOG_FILE
if [[ $? != 0 ]]; then 
    echo -e "${RED}Le serveur $SERVER est injoignable${ENDCOLOR}"
    warning_mail
    exit 112
else
    echo -e "${GREEN}Le serveur $SERVER répond${ENDCOLOR}"
fi
# Vérification de la présence du dossier de destination distant
ssh -p $PORT "$SSHUSER@$SERVER" "touch $DIRECT/autosynchrotest.test && rm -f $DIRECT/autosynchrotest.test > /dev/null 2>&1" > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo -e "${RED}Le dossier $DIRECT n'existe pas sur $SERVER ou est inaccessible en écriture par $SSHUSER${ENDCOLOR}"
    warning_mail
    exit 2
fi
# Vérification de la présence du dossier source local et des permissions
if [[ ! -d "$SOURCE" || ! -r "$SOURCE" ]]; then
    echo -e "${RED}Le dossier $SOURCE n'existe pas ou est inaccessible en lecture${ENDCOLOR}"
    warning_mail
    exit 2
fi
}
#
check_dir_loc2loc ()
{
# Vérification de la présence du dossier source local
if [[ ! -d "$SOURCE" || ! -r "$SOURCE" ]]; then
    echo -e "${RED}Le dossier $SOURCE n'existe pas ou est inaccessible en lecture${ENDCOLOR}"
    warning_mail
    exit 2
# Vérification de la présence du dossier de destination local
elif [[ ! -d "$DESTINATION" || ! -w "$DESTINATION" ]]; then
    echo -e "${RED}Le dossier $DESTINATION n'existe pas ou est inaccessible en écriture${ENDCOLOR}"
    warning_mail
    exit 2
fi
}
### Fonction appelée pour une sauvegarde depuis un serveur distant vers un dossier local ###
#
fromdist ()
{
# Récupération des valeurs serveur et dossier
declare -r SERVER=$(echo $SOURCE | cut -d ':' -f1)
declare -r DIRECT=$(echo $SOURCE | cut -d ':' -f2)
#
check_dir_fromdist
#
check_rsync
#
check_rsync_dist
#
# Vérification de l'espace disque
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir SPACE=$(rsync -arvn --stats --delete --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "Total transferred file size" | awk '{print $5}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
else
    declare -ir SPACE=$(rsync -arvn --stats --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "Total transferred file size" | awk '{print $5}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
fi
#
# Interruption du script si espace insuffisant
#
if [[ "$FREE" -lt "$SPACE" ]]; then
    echo -e "${RED}Espace disque insuffisant${ENDCOLOR}"
    warning_mail
    exit 28
fi
#
# Nombre d'éléments que contient le dossier source
#
declare -ir SOURCECONT=$(rsync -arvn --stats --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "Number of files" | awk '{print $4}' | sed s/[.]//g)-1
echo -e "${YELLOW}Le dossier source contient $SOURCECONT éléments${ENDCOLOR}"
#
# Nombre d'éléments à syncroniser
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir ELEMENTS=$(rsync -arvhn --delete --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
else
    declare -ir ELEMENTS=$(rsync -arvhn --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
fi
echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
#
# Interruption de la sauvegarde si plus de n% ou 0 éléments modifiés depuis la dernière sauvegarde
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [[ "$ELEMENTS" -gt "$ELEMAXI" ]]; then
    echo -e "${RED}Trop de modifications: $ELEMENTS - interruption du backup${ENDCOLOR}"
    warning_mail
    exit 109
elif [[ "$ELEMENTS" -eq 0 ]]; then
    echo -e "${GREEN}Aucune modification à effectuer${ENDCOLOR}"
    exit 0
fi
#
# Lancement de la sauvegarde
#
if [[ $SYNCRO == "yes" ]]; then
    echo -e "${GREEN}Synchronisation en cours${ENDCOLOR}"
    rsync -arhv --delete --exclude={$EXCLUDE} --progress -e "ssh -p $PORT" $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
else
    echo -e "${GREEN}Sauvegarde en cours${ENDCOLOR}"
    rsync -arhv --exclude={$EXCLUDE} --progress -e "ssh -p $PORT" $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
fi
}
#
### Fonction appelée pour une sauvegarde depuis un dossier local vers un serveur distant ###
#
todist ()
{
# Récupération des valeurs serveur et dossier
declare -r SERVER=$(echo $DESTINATION | cut -d ':' -f1)
declare -r DIRECT=$(echo $DESTINATION | cut -d ':' -f2)
#
check_dir_todist
#
check_rsync
#
check_rsync_dist
#
# Vérification de l'espace disque
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir SPACE=$(rsync -arvn --stats --delete --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep "Total transferred file size" | awk '{print $5}' | sed 's/[.]//g')
    declare TMPFREE=$(ssh -p $PORT $SERVER "df -BK $DIRECT | grep "/" | sed 's/[a-z]//gI' | sed 's/[/]//g'")
    declare -ir FREE=$(echo $TMPFREE | awk '{print $4}')*1000
else
    declare -ir SPACE=$(rsync -arvn --stats --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep "Total transferred file size" | awk '{print $5}' | sed 's/[.]//g')
    declare TMPFREE=$(ssh -p $PORT $SERVER "df -BK $DIRECT | grep "/" | sed 's/[a-z]//gI' | sed 's/[/]//g'")
    declare -ir FREE=$(echo $TMPFREE | awk '{print $4}')*1000
fi
#
# Interruption du script si espace insuffisant
#
if [[ "$FREE" -lt "$SPACE" ]]; then
    echo -e "${RED}Espace disque insuffisant${ENDCOLOR}"
    warning_mail
    exit 28
fi
#
# Nombre d'éléments que contient le dossier source
#
declare -ir SOURCECONT=$(rsync -arvn --stats --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "Number of files" | awk '{print $4}' | sed s/[.]//g)-1
echo -e "${YELLOW}Le dossier source contient $SOURCECONT éléments${ENDCOLOR}"
#
# Nombre d'éléments à syncroniser
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir ELEMENTS=$(rsync -arvn --delete --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
else
    declare -ir ELEMENTS=$(rsync -arvn --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
fi
#
# Interruption de la sauvegarde si plus de n% ou 0 éléments modifiés depuis la dernière sauvegarde
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [[ "$ELEMENTS" -gt "$ELEMAXI" ]]; then
    echo -e "${RED}Trop de modifications: $ELEMENTS - interruption du backup${ENDCOLOR}"
    warning_mail
    exit 109
elif [[ "$ELEMENTS" -eq 0 ]]; then
    echo -e "${GREEN}Aucune modification à effectuer${ENDCOLOR}"
    exit 0
fi
#
# Lancement de la sauvegarde
#
if [[ $SYNCRO == "yes" ]]; then
    echo -e "${GREEN}Synchronisation en cours${ENDCOLOR}"
    rsync -arhv --delete --exclude={$EXCLUDE} --progress $SOURCE -e "ssh -p $PORT" $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
else
    echo -e "${GREEN}Sauvegarde en cours${ENDCOLOR}"
    rsync -arhv --exclude={$EXCLUDE} --progress $SOURCE -e "ssh -p $PORT" $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
fi
}
#
### Fonction appelée pour une sauvegarde depuis un dossier local vers un dossier local ###
#
loc2loc ()
{
#
check_dir_loc2loc
#
check_rsync
#
# Vérification de l'espace disque
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir SPACE=$(rsync -arvn --stats --delete --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep "Total transferred file size" | awk '{print $5}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
else
    declare -ir SPACE=$(rsync -arvn --stats --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep "Total transferred file size" | awk '{print $5}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
fi
#
# Interruption du script si espace insuffisant
#
if [[ "$FREE" -lt "$SPACE" ]]; then
    echo -e "${RED}Espace disque insuffisant${ENDCOLOR}"
    warning_mail
    exit 28
fi
#
# Nombre d'éléments que contient le dossier source
#
declare -ir SOURCECONT=$(rsync -arvn --stats --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep "Number of files" | awk '{print $4}' | sed s/[.]//g)-1
echo -e "${YELLOW}Le dossier source contient $SOURCECONT éléments${ENDCOLOR}"
#
# Nombre d'éléments à syncroniser
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir ELEMENTS=$(rsync -arvhn --delete --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
else
    declare -ir ELEMENTS=$(rsync -arvhn --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
fi
#
# Interruption de la sauvegarde si plus de n% ou 0 éléments modifiés depuis la dernière sauvegarde
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [[ "$ELEMENTS" -gt "$ELEMAXI" ]]; then
    echo -e "${RED}Trop de modifications: $ELEMENTS - interruption du backup${ENDCOLOR}"
    warning_mail
    exit 109
elif [[ "$ELEMENTS" -eq 0 ]]; then
    echo -e "${GREEN}Aucune modification à effectuer${ENDCOLOR}"
    exit 0
fi
#
# Lancement de la sauvegarde
#
if [[ $SYNCRO == "yes" ]]; then
    echo -e "${GREEN}Synchronisation en cours${ENDCOLOR}"
    rsync -arhv --delete --exclude={$EXCLUDE} --progress $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
else
    echo -e "${GREEN}Sauvegarde en cours${ENDCOLOR}"
    rsync -arhv --exclude={$EXCLUDE} --progress $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
fi
}
#
##### Choix du type de sauvegarde #####
#
if [[ "$SOURCE" =~ "@" && ! "$DESTINATION" =~ "@"  ]]; then
    fromdist
elif [[ ! "$SOURCE" =~ "@" && "$DESTINATION" =~ "@"  ]]; then
    todist
elif [[ ! "$SOURCE" =~ "@" && ! "$DESTINATION" =~ "@"  ]]; then
    loc2loc
else 
    echo -e "${RED}Erreur de saisie dans le fichier de configuration (source et destination)${ENDCOLOR}"
    exit 2
fi
