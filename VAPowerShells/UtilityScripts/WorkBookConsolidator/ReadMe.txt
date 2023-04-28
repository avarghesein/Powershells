Consolidates Multiple Workbooks to a Single One.
Scan through all sheets based on pre defined mappings and merges rows:
(Requires Microsoft Excel To Be Available In The System)

1.SetPowershell Policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

2. Copy your Workbooks to Consolidate to 
\Reports\DATA\SRC

3. Run BuildWorbookFromTemplateSources.ps1

4. Find your output in 
\Reports\DATA\Output



PS:
* If you need to customize the field values like Market name, Segment name?

Come to \Reports\CustomMappings.json and define Market Name and Segment Name mappings

* If you need to remap columns of output excel

Come to \Reports\WorkbookTemplateMapping.json and
\Reports\ProcessWorkBookVariableTemplates.ps1

and customize the same

