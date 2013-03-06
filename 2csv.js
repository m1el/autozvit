var args = WScript.Arguments
if (args.length < 2) {
	WScript.Echo("Not enough arguments. \n"
		+ "Usage: 2dbf.js <input file> <optput dbf file>")
	WScript.Quit(1)
}
var
excel = new ActiveXObject("Excel.Application"),
fso = new ActiveXObject("Scripting.FileSystemObject"),
fullname = function(x){
	return fso.GetAbsolutePathName(x)
}
try {
	excel.Workbooks.Open(fullname(args(0)))
} catch(e) {
	WScript.Echo("Can't open input file " + args(0))
	excel.Quit()
	WScript.Quit(1)
}
excel.DisplayAlerts = false
excel.ActiveWorkbook.ActiveSheet.Cells(1, 2) = "KOD"
try {
	excel.ActiveWorkbook.SaveAs(fullname(args(1)), 24) // xlDBF2 = 7, xlDBF3 = 8, xlCSVMSDOS = 24
} catch(e) {
	WScript.Echo("Can't save to output file " + args(1))
	excel.ActiveWorkbook.Close(false)
	excel.Quit()
	WScript.Quit(1)
}
excel.ActiveWorkbook.Close(false)
excel.Quit()
