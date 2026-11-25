# Fidélisation des clients télécoms — environnement du projet

Ce dossier contient **uniquement l'environnement** : configuration, infrastructure Docker et dossiers vides.
**Aucun code, aucune donnée** : vous les ajoutez à leur emplacement (tableau du §5).

```
Postgres ─► Debezium+Kafka ─► S3 ─► Snowflake: RAW ─► CLEANED ─► BUSINESS ─► Power BI
 (source)      (CDC)        (lake)            └──────── dbt ────────┘
                                       Airflow orchestre · GitHub Actions + Docker = CI/CD
```

## 1. Prérequis

| Outil | Remarque |
|---|---|
| **Python 3.11 ou 3.12** | cocher « Add to PATH » sous Windows (éviter 3.13 : dbt-snowflake peut ne pas être compatible) |
| **VS Code** | accepter les extensions recommandées à l'ouverture du dossier |
| **Docker Desktop** | Windows : activer WSL2 ; allouer **≥ 6 Go de RAM** à Docker |
| **Git** + compte **GitHub** | |
| **Power BI Desktop** | Windows uniquement |
| **Snowflake** (essai 30 jours) | à créer quand vous arrivez à la couche warehouse |
| **AWS** (offre gratuite) | vrai bucket S3 pour Snowflake (Snowflake ne lit pas le MinIO local) |

## 2. Installation (chaque membre)

```bash
cp .env.example .env                    # Windows PowerShell : Copy-Item .env.example .env

python -m venv .venv
source .venv/bin/activate               # Windows : .venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m ipykernel install --user --name telecom-churn --display-name "Python (telecom-churn)"
```
Puis dans VS Code : **Fichier → Ouvrir le dossier**, **Python: Select Interpreter** → `.venv`, et dans un notebook **Sélectionner le noyau** → *Python (telecom-churn)*.

## 3. Démarrer l'infrastructure

```bash
docker compose up -d                              # Postgres, Kafka, Debezium, MinIO (~1 min : docker compose ps)
docker compose --profile airflow up -d --build    # + Airflow (plus lourd)
docker compose --profile airflow down             # tout arrêter  (down -v : repartir de zéro)
```
Sous Windows sans `make` : **Ctrl+Shift+P → Tasks: Run Task**. Avec `make` : `make up`, `make airflow`, `make ps`, `make down`.

| Service | Adresse | Identifiants |
|---|---|---|
| Postgres (source) | `localhost:5433` | voir `.env` |
| Kafka (depuis votre PC) | `localhost:29092` | — |
| Debezium Connect | http://localhost:8083 | — |
| Kafka UI | http://localhost:8088 | — |
| MinIO (S3 local) | http://localhost:9001 | `minioadmin` / `minioadmin` |
| Airflow | http://localhost:8081 | `admin` / `admin` |

Le bucket MinIO `telecom-datalake` est créé automatiquement. Dans le conteneur Debezium, la base s'appelle `source-db:5432` (et non `localhost:5433`).

## 4. Configuration déjà en place
- **`docker-compose.yml`** : infrastructure ci-dessus. Le consumer Kafka → S3 est à ajouter comme nouveau service.
- **`.env.example`** : toutes les variables (Postgres, Kafka, S3, Snowflake). Jamais commité une fois copié en `.env`.
- **`requirements.txt`** : pandas, scikit-learn, Jupyter, dbt-Snowflake, connecteurs Postgres/Kafka/S3/Snowflake.
- **`dbt/dbt_project.yml` + `profiles.yml`** : `models/silver` → schéma `CLEANED`, `models/gold` → schéma `BUSINESS` ; connexion Snowflake lue dans `.env`. Pour que les schémas portent exactement ces noms, il faudra ajouter la macro dbt `generate_schema_name` dans `dbt/macros/`.
- **`infra/airflow/Dockerfile`** : Airflow avec dbt installé dans un environnement séparé (`/home/airflow/dbt_venv/bin/dbt`).
- **`.vscode/`** : réglages, extensions recommandées (Python, Jupyter, Docker, dbt, Snowflake, GitLens, Jira), tâches Docker.
- **`.github/`** : CI minimale (lint, validation compose, `dbt parse`) et modèle de pull request.
- **`pyproject.toml`** : réglages `ruff` et `pytest`. **`.gitignore`**, **`.editorconfig`**, **`.gitattributes`** : bonnes pratiques d'équipe.

## 5. Où mettre le code et les données

| Dossier | Contenu à y mettre |
|---|---|
| `data/raw/` | vos fichiers `.txt` d'origine (non versionnés) |
| `data/interim/`, `data/processed/` | données intermédiaires / finales générées (non versionnées) |
| `infra/postgres/` | scripts `.sql` de création des tables sources (exécutés au 1er démarrage du conteneur) |
| `infra/debezium/` | configuration JSON du connecteur Debezium |
| `ingestion/` | scripts d'ingestion (chargement, consumer Kafka → S3, simulation) |
| `snowflake/` | scripts SQL du warehouse (entrepôt, schémas, rôles, stage S3, tables RAW) |
| `dbt/models/silver/` · `dbt/models/gold/` | modèles dbt des couches Cleaned et Business Ready |
| `dbt/macros/` · `dbt/tests/` | macros et tests dbt |
| `airflow/dags/` | DAG Airflow (monté dans le conteneur) |
| `src/` · `notebooks/` · `models/` | code Python réutilisable · notebooks · modèles entraînés (non versionnés) |
| `tests/` | tests Python (`pytest`) |
| `scripts/` | petits utilitaires |
| `powerbi/` | fichier `.pbix` |
| `docs/` | documentation, rapport |

## 6. Dépannage
| Symptôme | Solution |
|---|---|
| `port is already allocated` | un autre programme utilise le port : changer le mapping dans `docker-compose.yml` (la source utilise 5433 pour éviter un Postgres local) |
| Conteneurs lents ou qui redémarrent | Docker Desktop → Settings → Resources : ≥ 6 Go ; ne pas lancer Airflow si le PC est juste |
| `Activate.ps1` bloqué (Windows) | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| `pip install` échoue (dbt + ML ensemble) | créer un second venv `.venv-dbt` avec seulement `dbt-snowflake` |
| Snowflake `account not found` | `SNOWFLAKE_ACCOUNT` = `xy12345.eu-west-1` ou `org-compte`, **sans** `https://` ni `.snowflakecomputing.com` |

## 7. Statut
Vérifié : syntaxe de `docker-compose.yml` (profil Airflow inclus) et des fichiers de configuration. **Non vérifié** : le démarrage réel des conteneurs et la connexion à Snowflake, à tester par chacun à la première utilisation.
