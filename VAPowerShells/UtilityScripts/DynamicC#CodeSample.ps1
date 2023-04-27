CLS

$job = Start-Job -ScriptBlock {

$source = @"

using System;
using System.IO;
using System.Data;
using System.Data.OleDb;
using System.Linq;


public class ExcelUtils2
{
    public static int Add(int a, int b)
    {
        return (a + b);
    }

    public static DataTable ConvertExcelToDataTable(string FileName)  
    {  
    string logfile="C:\\Users\\331905\\Downloads\\file.txt";
    File.AppendAllText(logfile, "Starting" + Environment.NewLine);

    DataTable dtResult = null;  
   
    using(OleDbConnection objConn = new OleDbConnection( "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + FileName + ";Extended Properties='Excel 12.0;HDR=YES;IMEX=1;';"))  
    {  
        objConn.Open();  
        //int totalSheet = 0; //No of sheets on excel file  
        OleDbCommand cmd = new OleDbCommand();  
        OleDbDataAdapter oleda = new OleDbDataAdapter();  
        DataSet ds = new DataSet();  
        DataTable dt = objConn.GetOleDbSchemaTable(OleDbSchemaGuid.Tables, null);  
        string sheetName = "Sheet1$";  
        /*if (dt != null)  
        {  
            File.AppendAllText(logfile, "Access DB Schema" + Environment.NewLine);
            var tempDataTable = (from dataRow in dt.AsEnumerable()  
            where dataRow["TABLE_NAME"].ToString().Contains("FilterDatabase")  
            select dataRow).CopyToDataTable();  
            dt = tempDataTable;  
            totalSheet = dt.Rows.Count;  
            File.AppendAllText(logfile, "Get Schema row before" + Environment.NewLine); 
            sheetName = dt.Rows[0]["TABLE_NAME"].ToString(); 
            File.AppendAllText(logfile, sheetName + Environment.NewLine); 
        }  */
        cmd.Connection = objConn;  
        cmd.CommandType = CommandType.Text;  
        cmd.CommandText = "SELECT * FROM [" + sheetName + "]";  
        oleda = new OleDbDataAdapter(cmd);  
        oleda.Fill(ds, sheetName);  
        dtResult = ds.Tables[sheetName];  
        objConn.Close();  
        return dtResult;   
    }  
} 

 public static void Write(DataTable dt, string filePath)
        {
            int i = 0;
            StreamWriter sw = null;

            try
            {
                
                sw = new StreamWriter(filePath, false);

               
                for (i = 0; i < dt.Columns.Count - 1; i++)
                {

                    sw.Write(dt.Columns[i].ColumnName + " | ");

                }
                sw.Write(dt.Columns[i].ColumnName);
                sw.WriteLine();

              
                foreach (DataRow row in dt.Rows)
                {
                    object[] array = row.ItemArray;

                    for (i = 0; i < array.Length - 1; i++)
                    {
                        sw.Write(array[i].ToString() + " | ");
                    }
                    sw.Write(array[i].ToString());
                    sw.WriteLine();

                }

                sw.Close();
            }

            catch //(Exception ex)
            {
                
            }
        }
}
"@

CLS
$assembly = Add-Type -TypeDefinition $source -ReferencedAssemblies ("System.Data", "System.Xml","System.Data.DataSetExtensions") -OutputAssembly "C:\Users\331905\Downloads\test2.dll" -PassThru

$table = $assembly::ConvertExcelToDataTable("C:\Users\331905\Downloads\test.xlsx")
$table.DefaultView.RowFilter="Marks >= 2"
$table = $table.DefaultView.ToTable()
$assembly::Write($table,"C:\Users\331905\Downloads\table.txt")
}

Wait-Job $job
Receive-Job $job