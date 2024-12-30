import luigi
import logging
import pandas as pd
import time
import sqlalchemy
from datetime import datetime
from pipeline.extract import Extract
from pipeline.utils.db_conn import db_connection
from pipeline.utils.read_sql import read_sql_file
from sqlalchemy.orm import sessionmaker
import os

# Define DIR
DIR_ROOT_PROJECT = os.getenv("DIR_ROOT_PROJECT")
DIR_TEMP_LOG = os.getenv("DIR_TEMP_LOG")
DIR_TEMP_DATA = os.getenv("DIR_TEMP_DATA")
DIR_LOAD_QUERY = os.getenv("DIR_LOAD_QUERY")
DIR_LOG = os.getenv("DIR_LOG")

class Load(luigi.Task):
    
    def requires(self):
        return Extract()
    
    def run(self):
         
        # Configure logging
        logging.basicConfig(filename = f'{DIR_TEMP_LOG}/logs.log', 
                            level = logging.INFO, 
                            format = '%(asctime)s - %(levelname)s - %(message)s')
        
        #----------------------------------------------------------------------------------------------------------------------------------------
        # Read query to be executed
        try:
            # Read query to truncate src schema in dwh
            truncate_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/src-truncate_tables.sql'
            )

            # Read load query to staging schema
            customers_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-customers.sql'
            )
            
            sellers_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-sellers.sql'
            )
            
            product_category_name_translation_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-product_category_name_translation.sql'
            )
            
            products_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-products.sql'
            )
            
            orders_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-orders.sql'
            )
            
            order_items_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-order_items.sql'
            )
            
            order_payments_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-order_payments.sql'
            )
            
            order_reviews_query = read_sql_file(
                file_path = f'{DIR_LOAD_QUERY}/stg-order_reviews.sql'
            )
            
            
            logging.info("Read Load Query - SUCCESS")
            
        except Exception:
            logging.error("Read Load Query - FAILED")
            raise Exception("Failed to read Load Query")
        
        
        #----------------------------------------------------------------------------------------------------------------------------------------
        # Read Data to be load
        try:
            # Read csv
            customers = pd.read_csv(self.input()[0].path)
            sellers = pd.read_csv(self.input()[1].path)
            product_category_name_translation = pd.read_csv(self.input()[2].path)
            products = pd.read_csv(self.input()[3].path)
            orders = pd.read_csv(self.input()[4].path)
            order_items = pd.read_csv(self.input()[5].path)
            order_payments = pd.read_csv(self.input()[6].path)
            order_reviews = pd.read_csv(self.input()[7].path)
            
            
            logging.info(f"Read Extracted Data - SUCCESS")
            
        except Exception:
            logging.error(f"Read Extracted Data  - FAILED")
            raise Exception("Failed to Read Extracted Data")
        
        
        #----------------------------------------------------------------------------------------------------------------------------------------
        # Establish connections to DWH
        try:
            _, dwh_engine = db_connection()
            logging.info(f"Connect to DWH - SUCCESS")
            
        except Exception:
            logging.info(f"Connect to DWH - FAILED")
            raise Exception("Failed to connect to Data Warehouse")
        
        
        #----------------------------------------------------------------------------------------------------------------------------------------
        # Truncate all tables before load
        # This puropose to avoid errors because duplicate key value violates unique constraint
        try:            
            # Split the SQL queries if multiple queries are present
            truncate_query = truncate_query.split(';')

            # Remove newline characters and leading/trailing whitespaces
            truncate_query = [query.strip() for query in truncate_query if query.strip()]
            
            # Create session
            Session = sessionmaker(bind = dwh_engine)
            session = Session()

            # Execute each query
            for query in truncate_query:
                query = sqlalchemy.text(query)
                session.execute(query)
                
            session.commit()
            
            # Close session
            session.close()

            logging.info(f"Truncate Bookings Schema in DWH - SUCCESS")
        
        except Exception:
            logging.error(f"Truncate Bookings Schema in DWH - FAILED")
            
            raise Exception("Failed to Truncate Bookings Schema in DWH")
        
        
        
        #----------------------------------------------------------------------------------------------------------------------------------------
        # Record start time for loading tables
        start_time = time.time()  
        logging.info("==================================STARTING LOAD DATA=======================================")
        # Load to tables to src schema
        try:
            
            try:
                # Load customers tables    
                customers.to_sql('customers', 
                                    con = dwh_engine, 
                                    if_exists = 'append', 
                                    index = False, 
                                    schema = 'src')
                logging.info(f"LOAD 'src.customers' - SUCCESS")
                
                
                # Load sellers tables
                sellers.to_sql('sellers', 
                                    con = dwh_engine, 
                                    if_exists = 'append', 
                                    index = False, 
                                    schema = 'src')
                logging.info(f"LOAD 'src.sellers' - SUCCESS")
                
                
                # Load product_category_name_translation tables
                product_category_name_translation.to_sql('product_category_name_translation', 
                                con = dwh_engine, 
                                if_exists = 'append', 
                                index = False, 
                                schema = 'src')
                logging.info(f"LOAD 'src.product_category_name_translation' - SUCCESS")
                
                
                # Load products tables
                products.to_sql('products', 
                            con = dwh_engine, 
                            if_exists = 'append', 
                            index = False, 
                            schema = 'src')
                logging.info(f"LOAD 'src.products' - SUCCESS")
                
                
                # Load orders tables
                orders.to_sql('orders', 
                            con = dwh_engine, 
                            if_exists = 'append', 
                            index = False, 
                            schema = 'src')
                logging.info(f"LOAD 'src.orders' - SUCCESS")
                
                
                # Load order_items tables
                order_items.to_sql('order_items', 
                            con = dwh_engine, 
                            if_exists = 'append', 
                            index = False, 
                            schema = 'src')
                logging.info(f"LOAD 'src.order_items' - SUCCESS")
                
                
                # Load products_order_items tables
                order_payments.to_sql('order_payments', 
                                    con = dwh_engine, 
                                    if_exists = 'append', 
                                    index = False, 
                                    schema = 'src')
                logging.info(f"LOAD 'src.order_payments' - SUCCESS")
                
                
                # Load order_reviews tables
                order_reviews.to_sql('order_reviews', 
                                    con = dwh_engine, 
                                    if_exists = 'append', 
                                    index = False, 
                                    schema = 'src')
                logging.info(f"LOAD 'src.order_reviews' - SUCCESS")
                logging.info(f"LOAD All Tables To DWH-src - SUCCESS")
                
            except Exception:
                logging.error(f"LOAD All Tables To DWH-src - FAILED")
                raise Exception('Failed Load Tables To DWH-src')
            
            
            #----------------------------------------------------------------------------------------------------------------------------------------
            # Load to staging schema
            try:
                # List query
                load_stg_queries = [customers_query, sellers_query, 
                                    product_category_name_translation_query, products_query, 
                                    orders_query, order_items_query, 
                                    order_payments_query, order_reviews_query]
                
                # Create session
                Session = sessionmaker(bind = dwh_engine)
                session = Session()

                # Execute each query
                for query in load_stg_queries:
                    query = sqlalchemy.text(query)
                    session.execute(query)
                    
                session.commit()
                
                # Close session
                session.close()
                
                logging.info("LOAD All Tables To DWH-Staging - SUCCESS")
                
            except Exception:
                logging.error("LOAD All Tables To DWH-Staging - FAILED")
                raise Exception('Failed Load Tables To DWH-Staging')
        
        
            # Record end time for loading tables
            end_time = time.time()  
            execution_time = end_time - start_time  # Calculate execution time
            
            # Get summary
            summary_data = {
                'timestamp': [datetime.now()],
                'task': ['Load'],
                'status' : ['Success'],
                'execution_time': [execution_time]
            }

            # Get summary dataframes
            summary = pd.DataFrame(summary_data)
            
            # Write Summary to CSV
            summary.to_csv(f"{DIR_TEMP_DATA}/load-summary.csv", index = False)
            
                        
        #----------------------------------------------------------------------------------------------------------------------------------------
        except Exception:
            # Get summary
            summary_data = {
                'timestamp': [datetime.now()],
                'task': ['Load'],
                'status' : ['Failed'],
                'execution_time': [0]
            }

            # Get summary dataframes
            summary = pd.DataFrame(summary_data)
            
            # Write Summary to CSV
            summary.to_csv(f"{DIR_TEMP_DATA}/load-summary.csv", index = False)
            
            logging.error("LOAD All Tables To DWH - FAILED")
            raise Exception('Failed Load Tables To DWH')   
        
        logging.info("==================================ENDING LOAD DATA=======================================")
        
    #----------------------------------------------------------------------------------------------------------------------------------------
    def output(self):
        return [luigi.LocalTarget(f'{DIR_TEMP_LOG}/logs.log'),
                luigi.LocalTarget(f'{DIR_TEMP_DATA}/load-summary.csv')]