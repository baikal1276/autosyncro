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
b79bec3702ff6c15a1e0130b0593ec0544667f1fc2d85a41ce23693d0cfa9a3f