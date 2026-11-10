<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class ShiftPreference extends Model {protected $fillable=['user_id','period_id','work_date','shift_type_id','note'];}
