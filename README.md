# 3commas_csv_analyzer

## Description

Wondering how are the performace of your bots? 

This script will tell you the individual pair performce of your bot and give you key metrics of `deal_count, total_profit_percentage_from_total_volume, total_final_profit` per pair. It generates reports for *all time*, *last 30 days*, *last 7 days*, *last 24 hours*, *last 12 hours*, and *last 6 hours* 

The output stats are also in CSV format, you can use your favourite tool to process the data further if needed.


```
$ ruby 3commas_csv_analyszer.rb
File not found export.csv

    usage:
        ruby 3commas_csv_analyszer.rb <path to export csv>
            default export file name is export.csv in the same directory 3commas_csv_analyszer.rb
```
