# SQL - Advance
## Summary
The Timeless Value of SQL in a Data-Driven Age
SQL, the OG of database languages, might be old-school, but it remains a critical tool in today’s data-driven world. Its significance stems from several key aspects:

## Languages and Libraries Used
### Tools used - 
   - Visual Studio Code: https://apps.microsoft.com/detail/xp9khm4bk9fz7q?launch=true&mode=full&hl=en-us&gl=de&ocid=bingwebsearch
   - MySQL Workbench: https://app.sqldbm.com/Recent/
   - SqlDBM: https://app.sqldbm.com/Recent/
### List the programming languages - Python, SQL
### Libraries - Pandas, requests, BeautifulSoup, timezonefinder, datetime, lat_lon_parser 

### Please create python file to save your sql password and user API Key

## install if needed
### !pip install sqlalchemy
### !pip install pymysql

## Key Learnings
1. APIs are your friend: More reliable than web scraping for dynamic data
2. Design matters: A well-thought-out database schema saves hours of refactoring
3. Flexibility is crucial: Be prepared to adapt your code and design
4. Cloud automation: Leveraged cloud infrastructure to build a scalable, self-updating system that dynamically adapts to changing data requirements, ensuring seamless performance and reducing manual intervention.
   
## Challenges Overcame
Every step of this project was a learning curve, filled with technical challenges that pushed boundaries and opportunities that deepened expertise. Transitioning from static local data to dynamic API integration wasn’t just about coding—it was about adapting, problem-solving, and growing along the way. Here's how key challenges were tackled:
1. Dynamic API Integration
APIs and web sources are dynamic and, at times, unpredictable. Managing these variations required robust solutions:
   - Error Handling: API responses often threw curveballs. To prevent disruptions, I implemented dynamic error handling. For example, whenever an HTTP status code other than 200 was returned, safeguards ensured that the loops didn’t break. This added resilience to the scripts, ensuring smooth operations even when the data sources faltered.
   - Data Validation Checks: Empty or malformed JSON results were another hurdle. Processing these efficiently not only strengthened the scripts but also expanded my understanding of Python clauses and error management techniques.
 
2. Handling Time Zones with Precision
Displaying accurate date and time information for various cities demanded careful attention to time zones. I explored and implemented two distinct methods:
   - TimezoneFinder Library: For weather data, I passed city coordinates into the TimezoneFinder library. This pinpointed the correct time zone for each location.
   - AeroDataBox-ICAO API: For flight data, I used ICAO codes to extract time zone details directly from API responses.
Rather than choosing one method, I utilized both to broaden my skillset. This dual approach not only ensured accuracy but also enriched my understanding of diverse techniques for solving similar problems.

## Shortcut to the Good Stuff

Feeling adventurous? Nah? That’s cool! Skip the drama, the details, and the 5-cups-of-coffee-debugging phase. Just grab files 7, 8, 9 and gans_cloud.sql like you're reaching for the last slice of pizza. They’ve got everything you need to run a local pipeline and cloud functions without breaking a sweat (or your keyboard).

Why waste brain cells reinventing the wheel when these files are basically the Swiss Army knife of your project? You're welcome. 🚀
