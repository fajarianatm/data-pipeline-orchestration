# Data Pipeline Orchestration Project

This project is designed to build a comprehensive Extract, Load, and Transform (ELT) pipeline that ensures efficient data integration within a data warehouse. The system is intended for use in a marketplace environment, enabling the storage, management, and analysis of large volumes of diverse data. It also facilitates the management of sales performance, product trends, and operational data, supporting advanced analytics and reporting. The pipeline incorporates Slowly Changing Dimension (SCD) techniques, allowing for the tracking and handling of changes in dimensional data over time, ensuring that historical data remains accurate and consistent.

Before utilizing this repository, please refer to this [article](https://medium.com/@fajariana.tm/data-warehouse-report-part-2-implementing-scd-bda58edeb715) for a deeper understanding of the data warehouse design implemented here.

## How to Use This Project

### 1. Requirements

#### Operating System:
- Linux
- WSL (Windows Subsystem For Linux)

#### Tools:
- Dbeaver
- Docker
- Cron

#### Programming Languages:
- Python
- SQL

#### Python Libraries:
- Luigi
- Pandas
- Sentry-SDK

#### Platforms:
- Sentry

### 2. Preparations

#### Clone the Repository:
```bash
# LFS Clone
git lfs clone https://github.com/fajarianatm/data-pipeline-orchestration.git
```

- **Create Sentry Project** :
  - Open : https://www.sentry.io
  - Signup with email you want to get notifications abot the error
  - Create Project :
    - Select Platform : Python
    - Set Alert frequency : `On every new issue`
    - Create project name.
  - After create the project, **store SENTRY DSN of your project into .env file**.

- **Create temp dir**. Execute this on root project directory :
    ```
    mkdir pipeline/temp/data
    mkdir pipeline/temp/log
    ```
  
- In thats project directory, **create and use virtual environment**.
- In virtual environment, **install requirements** :
  ```
  pip install -r requirements.txt
  ```

- **Create env file** in project root directory :
  ```
  # Source
  SRC_POSTGRES_DB=...
  SRC_POSTGRES_HOST=...
  SRC_POSTGRES_USER=...
  SRC_POSTGRES_PASSWORD=...
  SRC_POSTGRES_PORT=...

  # DWH
  DWH_POSTGRES_DB=...
  DWH_POSTGRES_HOST=...
  DWH_POSTGRES_USER=...
  DWH_POSTGRES_PASSWORD=...
  DWH_POSTGRES_PORT=...

  # SENTRY DSN
  SENTRY_DSN=... # Fill with your Sentry DSN Project 

  # DIRECTORY
  # Adjust with your directory. make sure to write full path
  DIR_ROOT_PROJECT=...     # <project_dir>
  DIR_TEMP_LOG=...         # <project_dir>/pipeline/temp/log
  DIR_TEMP_DATA=...        # <project_dir>/pipeline/temp/data
  DIR_EXTRACT_QUERY=...    # <project_dir>/pipeline/src_query/extract
  DIR_LOAD_QUERY=...       # <project_dir>/pipeline/src_query/load
  DIR_TRANSFORM_QUERY=...  # <project_dir>/pipeline/src_query/transform
  DIR_LOG=...              # <project_dir>/logs/
    ```

- **Run Data Sources & Data Warehouses** :
  ```
  docker compose up -d
  ```

### 3. Orchestrate ELT Pipeline
- Create schedule to run pipline every one hour.
  ```
  0 * * * * <project_dir>/elt_run.sh
  ```


