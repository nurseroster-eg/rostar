<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {public function up():void {
Schema::create('departments',function(Blueprint $t){$t->id();$t->string('name')->unique();$t->timestamps();});
Schema::create('users',function(Blueprint $t){$t->id();$t->string('name');$t->string('employee_no')->nullable()->unique();$t->string('staff_code')->nullable();$t->string('email')->unique();$t->string('password');$t->enum('role',['admin','nurse'])->default('nurse');$t->foreignId('department_id')->nullable()->constrained()->nullOnDelete();$t->text('notes')->nullable();$t->boolean('is_active')->default(false);$t->rememberToken();$t->timestamps();});
Schema::create('shift_types',function(Blueprint $t){$t->id();$t->string('code',8)->unique();$t->string('name');$t->unsignedSmallInteger('minutes')->nullable();$t->boolean('is_off')->default(false);$t->timestamps();});
Schema::create('roster_periods',function(Blueprint $t){$t->id();$t->date('month')->unique();$t->enum('status',['open','closed','published'])->default('open');$t->dateTime('deadline')->nullable();$t->foreignId('published_by')->nullable()->constrained('users')->nullOnDelete();$t->timestamp('published_at')->nullable();$t->timestamps();});
Schema::create('shift_preferences',function(Blueprint $t){$t->id();$t->foreignId('user_id')->constrained()->cascadeOnDelete();$t->foreignId('period_id')->constrained('roster_periods')->cascadeOnDelete();$t->date('work_date');$t->foreignId('shift_type_id')->constrained();$t->text('note')->nullable();$t->timestamps();$t->unique(['user_id','work_date']);});
Schema::create('roster_assignments',function(Blueprint $t){$t->id();$t->foreignId('user_id')->constrained()->cascadeOnDelete();$t->foreignId('period_id')->constrained('roster_periods')->cascadeOnDelete();$t->date('work_date');$t->foreignId('shift_type_id')->constrained();$t->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();$t->timestamps();$t->unique(['user_id','work_date']);});
Schema::create('staffing_requirements',function(Blueprint $t){$t->id();$t->foreignId('department_id')->constrained()->cascadeOnDelete();$t->foreignId('shift_type_id')->constrained()->cascadeOnDelete();$t->unsignedSmallInteger('minimum_staff')->default(0);$t->unique(['department_id','shift_type_id']);});
Schema::create('audit_logs',function(Blueprint $t){$t->id();$t->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();$t->string('action');$t->string('entity');$t->unsignedBigInteger('entity_id')->nullable();$t->json('details')->nullable();$t->timestamps();});
}public function down():void{foreach(['audit_logs','staffing_requirements','roster_assignments','shift_preferences','roster_periods','shift_types','users','departments'] as $table)Schema::dropIfExists($table);}
};
