Package pour Debian et Debian based

Editez /etc/autosyncro/autosyncro.conf après le script post-installation pour modifier le chemin vers le fichier de log
si problème de permissions.

AutoSyncro v1.1.2

Dépendences:    - bash
                - rsync
Dépendences optionnelles:   - swaks
                            - cron

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
f8989e02e5b6fafbb5436f7ea4645d4a1893c8e7b71fe6794e64da7f995fc1c6
