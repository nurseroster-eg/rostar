<?php
namespace App\Models;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
class User extends Authenticatable {use Notifiable;protected $fillable=['name','employee_no','staff_code','email','password','role','department_id','notes','is_active'];protected $hidden=['password','remember_token'];protected function casts():array{return ['password'=>'hashed','is_active'=>'boolean'];}public function department(){return $this->belongsTo(Department::class);} }
