Package pour Debian et Debian based

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
d30e8f1a0d218f2afc670bfdac101bf3c304ba423c9eb05670e6be33f078d873