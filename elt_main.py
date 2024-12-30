import luigi
import sentry_sdk
import pandas as pd
from dotenv import load_dotenv
import os

from pipeline.extract import Extract
from pipeline.load import Load
from pipeline.transform import Transform
from pipeline.utils.concat_dataframe import concat_dataframes
from pipeline.utils.copy_log import copy_log
from pipeline.utils.delete_temp_data import delete_temp

# Load environment variables from .env file
load_dotenv()

# Read env variables
DIR_ROOT_PROJECT = os.getenv("DIR_ROOT_PROJECT")
DIR_TEMP_LOG = os.getenv("DIR_TEMP_LOG")
DIR_TEMP_DATA = os.getenv("DIR_TEMP_DATA")
DIR_LOG = os.getenv("DIR_LOG")
SENTRY_DSN = os.getenv("SENTRY_DSN")

# Track the error using sentry
sentry_sdk.init(
    dsn = f"{SENTRY_DSN}"
)

# Function to ensure a file exists with a specified header
def ensure_file_exists_with_header(file_path, header=None):
    if not os.path.exists(file_path):
        with open(file_path, 'w') as f:
            if header:
                f.write(header)



# Ensure pipeline_summary.csv exists with header
pipeline_summary_path = f'{DIR_ROOT_PROJECT}/pipeline_summary.csv'
ensure_file_exists_with_header(pipeline_summary_path, 'timestamp,task,status,execution_time\n')

# Ensure temp extract, load, and transform summary exists with header
for summary_file in ['extract-summary.csv', 'load-summary.csv', 'transform-summary.csv']:
    file_path = f'{DIR_TEMP_DATA}/{summary_file}'
    directory = os.path.dirname(file_path)
    
    # Check if directory exists, if not, create it
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    # Ensure file exists with the specified header
    ensure_file_exists_with_header(file_path, 'timestamp,task,status,execution_time\n')

# Ensure TEMP LOG exists
if not os.path.exists(DIR_TEMP_LOG):
    os.makedirs(DIR_TEMP_LOG)
    with open(f'{DIR_TEMP_LOG}/logs.log', 'w') as f:
        f.write('')

# Ensure logs.log exists
if not os.path.exists(DIR_LOG):
    os.makedirs(DIR_LOG)
    with open(f'{DIR_LOG}/logs.log', 'w') as f:
        f.write('')
    

# Execute the functions when the script is run
if __name__ == "__main__":
    # Build the task
    luigi.build([Extract(),
                 Load(),
                 Transform()])
    

    
    # Concat temp extract summary to final summary
    concat_dataframes(
        df1 = pd.read_csv(pipeline_summary_path),
        df2 = pd.read_csv(f'{DIR_TEMP_DATA}/extract-summary.csv')
    )
    
    # Concat temp load summary to final summary
    concat_dataframes(
        df1 = pd.read_csv(pipeline_summary_path),
        df2 = pd.read_csv(f'{DIR_TEMP_DATA}/load-summary.csv')
    )
    
    # Concat temp transform summary to final summary
    concat_dataframes(
        df1 = pd.read_csv(pipeline_summary_path),
        df2 = pd.read_csv(f'{DIR_TEMP_DATA}/transform-summary.csv')
    )
    
    # Ensure logs.log exists
    logs_path = f'{DIR_LOG}/logs.log'
    ensure_file_exists_with_header(logs_path)
    
    # Append log from temp to final log
    copy_log(
        source_file = f'{DIR_TEMP_LOG}/logs.log',
        destination_file = logs_path
    )
    
    # Delete temp data
    delete_temp(
        directory = f'{DIR_TEMP_DATA}'
    )
    
    # Delete temp log
    delete_temp(
        directory = f'{DIR_TEMP_LOG}'
    )