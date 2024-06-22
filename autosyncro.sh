#!/bin/bash
#                                       ##############
#                                       # AutoSyncro #
#                                       ##############
# Version 1.0
#
# Par Baikal276
#
# 21 juin 2024
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
# --- tree (essentiel pour la vérification du nombre d'éléments à transférer) ---
# --- ssh-agent préalablement configuré pour la gestion des clés et passphrase si dossier distant défini ---
# https://wiki.archlinux.org/title/SSH_keys
# - (((Optionnel))) s-nail préalablement configuré pour l'envoi d'emails (((Optionnel)))
# https://www.linuxtricks.fr/wiki/ssmtp-msmtp-mail-s-nail-envoyer-des-emails-facilement-sous-linux-en-ligne-de-commande
#
# ///// Dépendances sur le serveur distant: \\\\\
#
# --- rsync (essentiel pour la sauvegarde) ---
# --- tree (essentiel pour la vérification du nombre d'éléments à transférer) ---
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
if [[ $MAIL =~ "@" ]]; then
    echo "La sauvegarde à échouée, voir $LOG_FILE" | s-nail -s "Echec durant la sauvegarde" $MAIL
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
### Fonctions de vérifications des cibles sources, destinations et serveurs ###
#
check_fromdist ()
{
# Isolation des valeurs relatives au serveur, au dossier source et à l'utilisateur
declare -r SERVER=$(echo $SOURCE | cut -d ':' -f1 | cut -d '@' -f2)
declare -r DIRECT=$(echo $SOURCE | cut -d ':' -f2)
declare -r SSHUSER=$(echo $SOURCE | cut -d ':' -f1 | cut -d '@' -f1)
# Vérification de la disponibilité du serveur
ping -c 2 $SERVER >> $LOG_FILE
if [[ $? != 0 ]]; then 
    echo -e "${RED}Le serveur $SERVER est injoignable${ENCOLOR}"
    warning_mail
    exit 112
else
    echo -e "${GREEN}Le serveur $SERVER répond${ENDCOLOR}"
fi
# Vérification de la présence du dossier source distant
ssh -p $PORT "$SSHUSER@$SERVER" "ls $DIRECT > /dev/null 2>&1" > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo -e "${RED}Le dossier $DIRECT n'existe pas sur $SERVER ou est inaccessible par $SSHUSER${ENCOLOR}"
    warning_mail
    exit 2
fi
# Vérification de la présence du dossier de destination local
if [[ ! -d "$DESTINATION" ]]; then
    echo -e "${RED}Le dossier $DESTINATION n'existe pas${ENCOLOR}"
    warning_mail
    exit 2
fi
}
#
check_todist ()
{
# Isolation des valeurs relatives au serveur, au dossier de destination et à l'utilisateur
declare -r SERVER=$(echo $DESTINATION | cut -d ':' -f1 | cut -d '@' -f2)
declare -r DIRECT=$(echo $DESTINATION | cut -d ':' -f2)
declare -r SSHUSER=$(echo $DESTINATION | cut -d ':' -f1 | cut -d '@' -f1)
# Vérification de la disponibilité du serveur
ping -c 2 $SERVER >> $LOG_FILE
if [[ $? != 0 ]]; then 
    echo -e "${RED}Le serveur $SERVER est injoignable${ENCOLOR}"
    warning_mail
    exit 112
else
    echo -e "${GREEN}Le serveur $SERVER répond${ENDCOLOR}"
fi
# Vérification de la présence du dossier de destination distant
ssh -p $PORT "$SSHUSER@$SERVER" "ls $DIRECT > /dev/null 2>&1" > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo -e "${RED}Le dossier $DIRECT n'existe pas sur $SERVER ou est inaccessible par $SSHUSER${ENCOLOR}"
    warning_mail
    exit 2
fi
# Vérification de la présence du dossier source local
if [[ ! -d "$SOURCE" ]]; then
    echo -e "${RED}Le dossier $SOURCE n'existe pas${ENCOLOR}"
    warning_mail
    exit 2
fi
}
#
check_loc2loc ()
{
# Vérification de la présence du dossier source local
if [[ ! -d "$SOURCE" ]]; then
    echo -e "${RED}Le dossier $SOURCE n'existe pas${ENCOLOR}"
    warning_mail
    exit 2
# Vérification de la présence du dossier de destination local
elif [[ ! -d "$DESTINATION" ]]; then
    echo -e "${RED}Le dossier $DESTINATION n'existe pas${ENCOLOR}"
    warning_mail
    exit 2
fi
}
### Fonction appelée pour une sauvegarde depuis un serveur distant vers un dossier local ###
#
fromdist ()
{
#
check_fromdist
#
# Vérification de l'espace disque
#
declare -ir SPACE=$(rsync -arvn --exclude $EXCLUDE -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-Z]//g')*1000
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
declare -r SERVER=$(echo $SOURCE | cut -d ':' -f1)
declare -r DIRECT=$(echo $SOURCE | cut -d ':' -f2)
declare -ir SOURCECONT=$(ssh -p $PORT $SERVER "tree $DIRECT | wc -l")-2
echo -e "${YELLOW}Le dossier source contient $SOURCECONT éléments${ENDCOLOR}"
#
# Nombre d'éléments à syncroniser
#
declare -ir ELEMENTS=$(rsync -arvhn --exclude $EXCLUDE -e "ssh -p $PORT" $SOURCE $DESTINATION | wc -l)-4
echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
#
# Interruption de la sauvegarde si plus de n% ou 0 éléments modifiés depuis la dernière sauvegarde
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [ "$ELEMENTS" -gt "$ELEMAXI" ]; then
    echo -e "${RED}Trop de modifications: $ELEMENTS - interruption du backup${ENDCOLOR}"
    warning_mail
    exit 109
elif [ "$ELEMENTS" -eq 0 ]; then
    echo -e "${GREEN}Aucune modification à effectuer${ENDCOLOR}"
    exit 0
#
# Lancement de la sauvegarde
#
else
    echo -e "${GREEN}Sauvegarde en cours${ENDCOLOR}"
    rsync -arhv --exclude $EXCLUDE --progress -e "ssh -p $PORT" $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
fi
}
#
### Fonction appelée pour une sauvegarde depuis un dossier local vers un serveur distant ###
#
todist ()
{
#
check_todist
#
# Récupération des valeurs serveur et dossier
#
declare -r SERVER=$(echo $DESTINATION | cut -d ':' -f1)
declare -r DIRECT=$(echo $DESTINATION | cut -d ':' -f2)
#
# Vérification de l'espace disque
#
declare -ir SPACE=$(rsync -arvn --exclude $EXCLUDE $SOURCE -e "ssh -p $PORT" $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
declare TMPFREE=$(ssh -p $PORT $SERVER "df -BK $DIRECT | grep "/" | sed 's/[a-Z]//g' | sed 's/[/]//g'")
declare -ir FREE=$(echo $TMPFREE | awk '{print $4}')*1000
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
declare -ir SOURCECONT=$(tree $SOURCE | wc -l)-2
echo -e "${YELLOW}Le dossier source contient $SOURCECONT éléments${ENDCOLOR}"
#
# Nombre d'éléments à syncroniser
#
declare -ir ELEMENTS=$(rsync -arvn --exclude $EXCLUDE $SOURCE -e "ssh -p $PORT" $DESTINATION| wc -l)-4
echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
#
# Interruption de la sauvegarde si plus de n% ou 0 éléments modifiés depuis la dernière sauvegarde
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [ "$ELEMENTS" -gt "$ELEMAXI" ]; then
    echo -e "${RED}Trop de modifications: $ELEMENTS - interruption du backup${ENDCOLOR}"
    warning_mail
    exit 109
elif [ "$ELEMENTS" -eq 0 ]; then
    echo -e "${GREEN}Aucune modification à effectuer${ENDCOLOR}"
    exit 0
#
# Lancement de la sauvegarde
#
else
    echo -e "${GREEN}Sauvegarde en cours${ENDCOLOR}"
    rsync -arhv --exclude $EXCLUDE --progress $SOURCE -e "ssh -p $PORT" $DESTINATION >> $LOG_FILE
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
check_loc2loc
#
# Vérification de l'espace disque
#
declare -ir SPACE=$(rsync -arvn --exclude $EXCLUDE $SOURCE $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-Z]//g')*1000
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
declare -ir SOURCECONT=$(tree $SOURCE | wc -l)-2
echo -e "${YELLOW}Le dossier source contient $SOURCECONT éléments${ENDCOLOR}"
#
# Nombre d'éléments à syncroniser
#
declare -ir ELEMENTS=$(rsync -arvhn --exclude $EXCLUDE $SOURCE $DESTINATION | wc -l)-4
echo -e "${YELLOW}$ELEMENTS éléments à modifiés${ENDCOLOR}"
#
# Interruption de la sauvegarde si plus de n% ou 0 éléments modifiés depuis la dernière sauvegarde
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [ "$ELEMENTS" -gt "$ELEMAXI" ]; then
    echo -e "${RED}Trop de modifications: $ELEMENTS - interruption du backup${ENDCOLOR}"
    warning_mail
    exit 109
elif [ "$ELEMENTS" -eq 0 ]; then
    echo -e "${GREEN}Aucune modification à effectuer${ENDCOLOR}"
    exit 0
#
# Lancement de la sauvegarde
#
else
    echo -e "${GREEN}Sauvegarde en cours${ENDCOLOR}"
    rsync -arhv --exclude $EXCLUDE --progress $SOURCE $DESTINATION >> $LOG_FILE
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