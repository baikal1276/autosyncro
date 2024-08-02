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
0d66c9772438005a0f3bf06b76d6a685c1f5a134d16116d138347b94fc3940c7