# AutoSyncro
# Version 1.1.1
# Nouveau dans cette version: remplacement de s-nail par swaks pour l'envoi d'un email en cas d'échec
#
# Par Baikal1276
#
# 01 juillet 2024
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
