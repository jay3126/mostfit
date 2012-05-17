# dataTables.js

## Instructions for writing reports such that the datatables jquery plugin can be applied on the reports that are generated

+ Whenever you create a table please follow the standard HTML5 table structure:-
  > <table>
  >	 <thead>
  >		<tr>
  >			<th></th>
  >		</tr>
  > 	 </thead>
  > 	 <tbody>
  >	 ...
  > 	 </tbody>
  >	 <tfoot>
  >      ...
  > 	 </tfoot>
  > </table>
+ Following these conventions is important because the dataTables.js uses the table structure to identify **table header**, **table body** and **table footer**.
+ Other functions like sorting are all designed under the assumption that the table in question is following HTML5 strict standards for tables.
+ Right now dataTables.js does not work for rowspanned or colspanned data. More investigation needs to be done on that
+ A sample has been created for the Daily Transaction Summary Report

## TODO:-
+ Displaying data with colspanned and rowspanned data
+ Sorting using table headers
+ exporting to csv and other formats using the **table tools** plugin
+ styling the search bar and the dropdown as well as the links that paginate the display