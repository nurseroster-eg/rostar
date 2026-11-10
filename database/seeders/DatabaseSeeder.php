<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\{User,ShiftType,Department};
class DatabaseSeeder extends Seeder {public function run():void {
Department::firstOrCreate(['name'=>'التمريض العام']);
foreach([['E','صباحي',null,false],['N','ليلي',null,false],['8','8 ساعات',480,false],['#','راحة',0,true]] as [$code,$name,$minutes,$off]) ShiftType::updateOrCreate(['code'=>$code],['name'=>$name,'minutes'=>$minutes,'is_off'=>$off]);
$email=env('ROSTER_ADMIN_EMAIL');$password=env('ROSTER_ADMIN_PASSWORD');
if(!$email||!$password||strlen($password)<12)throw new \RuntimeException('Set ROSTER_ADMIN_EMAIL and ROSTER_ADMIN_PASSWORD (12+ chars) before seeding.');
User::updateOrCreate(['email'=>$email],['name'=>'مدير التمريض','role'=>'admin','password'=>$password,'is_active'=>true]);
}}
