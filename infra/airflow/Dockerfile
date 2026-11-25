FROM apache/airflow:2.10.3-python3.11

USER airflow

# dbt est installé dans un venv séparé : évite les conflits de dépendances avec Airflow.
# Les DAG l'appellent via /home/airflow/dbt_venv/bin/dbt
RUN python -m venv /home/airflow/dbt_venv \
 && /home/airflow/dbt_venv/bin/pip install --no-cache-dir --upgrade pip \
 && /home/airflow/dbt_venv/bin/pip install --no-cache-dir "dbt-snowflake>=1.8,<1.10"
