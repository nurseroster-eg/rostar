<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class RosterPeriod extends Model {protected $fillable=['month','status','deadline','published_by','published_at'];protected function casts():array{return ['month'=>'date','deadline'=>'datetime','published_at'=>'datetime'];}}
