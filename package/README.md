Package pour Debian et Debian based

Editez /etc/autosyncro/autosyncro.conf après le script post-installation pour modifier le chemin vers le fichier de log
si problème de permissions.

AutoSyncro v1.1.2

Dépendences:    - bash
                - rsync
Dépendences optionnelles:   - swaks
                            - cron

Rsync doit être installé sur le serveur distant dans le cas d'une sauvegarde via ssh

Contenu du package autosyncro.deb
.
├── autosyncro
│   ├── DEBIAN
│   │   ├── control
│   │   └── postinst
│   ├── etc
│   │   └── autosyncro
│   │       └── autosyncro.conf
│   └── usr
│       ├── bin
│       │   └── autosyncro
│       └── share
│           └── autosyncro
│               └── README.md
└── autosyncro.deb

sha256sum:
2dcc5bf88e61b2ac1dd853773f97b17005234277237a1887019fa7ac95c51099