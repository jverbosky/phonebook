## Phonebook ##

A phonebook directory web app developed using Ruby, Sinatra, HTML and CSS. Data hosted on an AWS-hosted PostgreSQL database.

Highlights include:

1. Support for record creation, retrieval, modification and deletion.
2. Field validation for record creation and modification.
3. Partial and case-insensitive search of existing records.
4. Modern, mobile device friendly UI via Bootstrap and Jasny Bootstrap.
5. AWS-hosted PostgreSQL database for data storage and retrieval.

----------

## Preliminaries ##

**Database Setup**

This application was developed to use an AWS-hosted PostgreSQL database.  However, the original database was taken offline due to AWS free-tier limits.

That being said, there are two Ruby programs in place to build and seed the database tables required by this web app.  To accomplish this, do the following:

1. Make sure the '[pg](https://github.com/ged/ruby-pg)' Ruby gem is installed.
2. Create an AWS-hosted PostgreSQL database instance through [RDS](https://us-west-2.console.aws.amazon.com/rds/home?region=us-west-2#).
3. In the **/methods** directory, create a file named **local_env.rb** that contains the necessary authentication details to connect to the AWS-hosted database.  For example:

    ENV['dbuser']='admin'  # user  
    ENV['dbpassword']='password'  # password  
    ENV['domain']='http://localhost:9292/phonebook'  
    ENV['dbname']='phonebook'  
    ENV['host']='phonebook.abcdef123456.us-west-2.rds.amazonaws.com'  # AWS link  
    ENV['port']='5432'  # AWS port, always 5432  

4. Navigate to the **/methods** directory in a terminal (command prompt) session.
5. Run the following command to connect to the AWS-hosted database and build the tables required by the phonebook app:

	ruby 1\_drop\_and\_create_tables.rb

6. Next, run the following command to populate the tables created in the previous step with seed data:

	ruby 2\_add\_data_tables.rb

7. To verify the database has been populated, you can either use a PostgreSQL browser such as PGAdmin or DBeaver, or you can run the following command:

	ruby 3\_query\_all_data.rb

----------

**Running the App**

To run the phonebook app locally:

1. Make sure that [Ruby](https://www.ruby-lang.org/en/documentation/installation/) is installed.
2. Make sure that the [Sinatra](https://github.com/sinatra/sinatra) gem is installed.  *Note that installing the Sinatra gem will install other gems necessary to run the game locally, such as rack.*
3. Navigate to the directory which contains **app.rb** in a terminal (command prompt) session.
4. Run the following command to launch the Sinatra web server:

	`rackup`

To open the app locally once it is running via *rackup*, use the following URL:

[http://localhost:9292](http://localhost:9292/)

----------

## Using the App ##

The following sections provide details on how to use the phonebook app.

----------

**Adding Entries**

----------

To add a new entry to the phonebook, do the following:

1. Select the **New** button from the top menu.
2. On the subsequent page, specify the entry details in the provided fields:

	- **First Name**
		- required field
		- must be *at least* 2 characters long
		- must not exceed 50 characters
		- valid characters include A-Z, a-z, period (.), hyphen (-) and space ( )
	- **Last Name**
		- required field
		- must be *at least* 2 characters long
		- must not exceed 50 characters
		- valid characters include A-Z, a-z, period (.), hyphen (-) and space ( )
	- **Street Address**
		- required field
		- must contain at least 3 values (number, name, street type)
		- must not exceed 50 characters
		- valid characters include 0-9, A-Z, a-z, period (.), hyphen (-) and space ( )
	- **City**
		- required field
		- must be *at least* 2 characters long
		- must not exceed 25 characters
	- **State**
		- required field
		- must be a valid 2-character state abbreviation
	- **Zip Code**
		- required field
		- must be exactly 5 digits
		- only numbers accepted as valid characters
	- **Mobile Phone**
		- if specified, must be exactly 9 digits
		- only numbers accepted as valid characters
	- **Home Phone**
		- required field
		- must be exactly 9 digits
		- only numbers accepted as valid characters
	- **Work Phone** 
		- if specified, must be exactly 9 digits
		- only numbers accepted as valid characters

3. Select the **Submit** button to add the entry to the phonebook.

*Note that if the entry is exactly the same as an existing entry, it will be rejected as a duplicate.*

----------

**Listing All Entries**

----------

To list all of the entries in the phonebook, do the following:

1. Select the **List** button from the top menu.
2. The subsequent page will provide an alphabetical listing of all entries in the phonebook.
3. Select an entry to view its associated details.

----------

**Searching for Entries**

----------

To search for an entry in the phonebook, do the following:

1. Select a field from the drop-down in the upper-right of the top menu.
2. Specify the search string in the *Search* field next to the drop-down.    
	- Note that the search supports partial matches and is case-insensitive.
	- For example, searching **Last Name** using "d" would return both "John Doe" and "Jen Addy".  
3. Select the magnifying glass button (or press Enter on the keyboard) to perform the search.
4. The subsequent page will provide an alphabetical listing of all entries in the phonebook that match the provided search criteria, if any exist.
5. Select an entry to view its associated details.

----------

**Updating Entries**

----------

To update the details for an entry in the phonebook, do the following:

1. Use the steps for **Listing All Entries** or **Searching for Entries** view the associated details for an entry.
2. (Listing All Entries only) Select the **Update** button.
3. On the update page, provide the corrected details as desired.
4. Select the **Submit** button to update the entry in the phonebook.

----------

**Deleting Entries**

----------

To update the details for an entry in the phonebook, do the following:

1. Use the steps for **Listing All Entries** or **Searching for Entries** view the associated details for an entry.
2. Select the **Delete** button.
3. On the *Confirmation Required* page, select the **Confirm** button to completely remove the entry from the phonebook.

*Note that deleting an entry from the phonebook will remove its record from the database.  Unless the database has been backed up, there will be no way to recover a deleted record.*

----------
## Tests ##

Please refer to the following sections for details on how to run the unit tests for the web app.

----------

**Unit Tests Overview**

----------

Tests have been developed to verify that the methods in each class file are working as intended.  All tests are located in the **/tests** directory.

Unit Tests:

- **test\_phonebook_ops.rb** > **/methods/phonebook\_ops.rb** (76 tests)

----------

**Preparing to Run Tests**

----------
In order to connect to the database and prepare the database, the unit test version of the "load local_env.rb" statement in **phonebook_ops.rb** must be used.

*Note that running the unit tests will purge the the current data set from the database, so testing against a local database instance instead of a production database is recommended if loss of data is unacceptable.*

----------

**Running Unit Tests**

----------

Once the correct "load local_env.rb" statement is available, unit tests can be run by doing the following:

1. Navigate to the **/tests** directory in a terminal (command prompt) session
2. Run the following command for the unit test file:<br>

    ruby test\_phonebook_ops.rb

The resulting output will indicate the success of the unit tests:

	Run options: --seed 58093

	# Running:

	............................................................................

	Finished in 0.587668s, 129.3247 runs/s, 129.3247 assertions/s.

	76 runs, 76 assertions, 0 failures, 0 errors, 0 skips

----------

Enjoy!