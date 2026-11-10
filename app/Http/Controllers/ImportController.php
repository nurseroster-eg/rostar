<?php
namespace App\Http\Controllers;
use App\Models\{User,Department,RosterPeriod,ShiftType,ShiftPreference};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use PhpOffice\PhpSpreadsheet\IOFactory;
class ImportController extends Controller {
public function import(Request $r){abort_unless(auth()->user()->role==='admin',403);$r->validate(['file'=>'required|file|mimes:xlsx,xls|max:5120','month'=>'required|date_format:Y-m']);$sheet=IOFactory::load($r->file('file')->getRealPath())->getSheet(0);$rows=$sheet->toArray(null,true,true,false);abort_unless(count($rows)>=3,422);abort_unless(trim((string)($rows[0][0]??''))==='رقم الموظف'&&trim((string)($rows[0][1]??''))==='اسم الممرض',422);$period=RosterPeriod::firstOrCreate(['month'=>$r->month.'-01']);abort_if($period->status==='published',403);$shifts=ShiftType::all()->keyBy('code');$department=Department::firstOrCreate(['name'=>'التمريض العام']);$days=(int)date('t',strtotime($r->month.'-01'));$count=0;$skipped=[];
DB::transaction(function()use($rows,$period,$shifts,$department,$days,&$count,&$skipped,$r){foreach(array_slice($rows,2) as $offset=>$row){$employee=trim((string)($row[0]??''));$name=trim((string)($row[1]??''));if(!$employee||!$name)continue;$user=User::firstOrCreate(['employee_no'=>$employee],['name'=>$name,'staff_code'=>(string)($row[2]??''),'notes'=>(string)($row[3]??''),'email'=>'import-'.Str::lower(Str::random(24)).'@placeholder.invalid','password'=>Str::random(48),'role'=>'nurse','department_id'=>$department->id,'is_active'=>false]);if($user->role!=='nurse')continue;$count++;for($day=1;$day<=$days;$day++){$raw=trim((string)($row[$day+3]??''));$code=Str::upper($raw);if(!isset($shifts[$code])){if($raw!=='')$skipped[]='صف '.($offset+3).' يوم '.$day.': '.$raw;continue;}$date=sprintf('%s-%02d',$r->month,$day);ShiftPreference::updateOrCreate(['user_id'=>$user->id,'work_date'=>$date],['period_id'=>$period->id,'shift_type_id'=>$shifts[$code]->id]);}}});return back()->with('ok',"تم استيراد $count ممرضًا. الرموز غير المعروفة: ".count($skipped))->with('import_warnings',array_slice($skipped,0,30));}
}
