# AutoSyncro
# Version 1.0
#
# Par Baikal1276
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
