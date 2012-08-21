#coding: utf-8

#ここはリファクタリング対象外
class MockEmployee
   attr_reader :name
   attr_reader :payment_base
   attr_reader :bonus_factor
   attr_reader :enter_at
   attr_reader :position

  def initialize(name, payment_base, bonus_factor, enter_at, position)
    @name = name
    @payment_base = payment_base
    @bonus_factor = bonus_factor
    @enter_at = enter_at
    @position = position
  end
end

class MockEmployeeDB
  def initialize
    @member = []
    @member << MockEmployee.new('alice', 100.0, 2, Time.gm(2007,10,1), :none) 
    @member << MockEmployee.new('bob', 120.0, 1, Time.gm(2002,9,1), :section_manager)
    @member << MockEmployee.new('charlie', 150.0, 3, Time.gm(2010,4,1), :group_leader)
    @member << MockEmployee.new('dave', 200.0, 2, Time.gm(2007,1,1), :general_manager)
    @member << MockEmployee.new('eve', 150.0, 0, Time.gm(2012,4,1), :none)
  end

  def method_missing(method, *args, &block)
    @member.send(method, *args, &block)
  end
end
#ここまでリファクタリング対象外

class Employee
  def initialize
    @employee_db = MockEmployeeDB.new
  end

  def get_members
    @employee_db.map{|member| member.name }
  end
  
  def got_bonus?(enter_at)
    # この month と year どっからきてんだ
    month + year * 12 >= enter_at.month + enter_at.year * 12 + 6
  end
  
  def calculate_payment(base)
    base
  end
  
  def calculate_payment_with_bonus(base, factor)
    base * case factor
      when 1
        1.1
      when 2
        1.2
      when 3
        1.3
      else
        1
      end
    end
  end
  
  def payment_revision_factor(position)
   case position
    when :section_manager
      2
    when :group_leader
      1.5
    when :general_manager
      10
    else
      1
    end
  end

  def get_payment(year, month)
    result = {}
    @employee_db.each do |member|
      payment = if got_bonus?(member.enter_at)
         calculate_payment_with_bonus(member.payment_base, member.bonus_factor)
      else
         calculate_payment(member.payment_base)
      end

      payment *= payment_revision_factor(member.position)

      result[member.name] = payment
    end
    result
  end
  
  # 関数内関数にしたいができない ruby のバカ
  def holiday_revision(position)
    case position
    when :section_manager
      -5
    when :group_leader
      -2
    when :general_manager
      -10
    else
      0
    end
  end
  
  def got_holiday_bonus?(enter_at)
    # この month と year どっからきてんだ
    month + year * 12 >= enter_at.month + enter_at.year * 12 + 6
  end
  
  def calculate_holiday_bonus(enter_at)
    # この month と year どっからきてんだ
    (month + year * 12 - (enter_at.month + enter_at.year * 12)) / 12 + 1
  end
  
  def base_holiday
    10
  end

  def get_holiday(year, month)
    @employee_db.group_by{|member| member.name }.map{|members|
      holiday = base_holiday
      member = members.first # name の一意性の保障はどこにもないけどまあ元のコードがアレなので知らん
      if got_holidary_bonus?(member.enter_at)
        holiday += calculate_holidary_bonus(member.enter_at)
      end
      holiday + holiday_revision(member.position)
    }
  end

  def get_work_month(year, month)
    result = {}
    @employee_db.each do |member|
      result[member.name] = month + year * 12 - (member.enter_at.month + member.enter_at.year * 12)
    end
    result
  end
end

class EmployeeView
  def initialize
    @employee = Employee.new
  end

  def view_employee(year, month)
    result = ""
    result += "<table>\n"

    result += "<tr>"
    result += "<th>名前</th>"
    result += "<th>休暇日数</th>"
    result += "<th>給与金額</th>"
    result += "<th>勤続年数</th>"
    result += "</tr>"
    result += "\n"

    payment = @employee.get_payment(year, month)
    holiday = @employee.get_holiday(year, month)
    work_month = @employee.get_work_month(year, month)

    # 休暇日数や、給与金額の最小・最大値の取得
    payment_max = nil
    payment_min = nil
    holiday_max = nil
    holiday_min = nil
    @employee.get_members.each do |member|
      payment_max = payment[member] if payment_max == nil || payment[member] > payment_max
      payment_min = payment[member] if payment_min == nil || payment[member] < payment_min
      holiday_max = holiday[member] if holiday_max == nil || holiday[member] > holiday_max
      holiday_min = holiday[member] if holiday_min == nil || holiday[member] < holiday_min
    end

    @employee.get_members.each do |member|
      result += "<tr>"
      result += "<td>#{member}</td>"
      if holiday[member] == holiday_min
        result += "<td style=\"color: blue\">#{holiday[member]}</td>"
      elsif holiday[member] == holiday_max
        result += "<td style=\"color: green\">#{holiday[member]}</td>"
      else
        result += "<td>#{holiday[member]}</td>"
      end

      if payment[member] == payment_min
        result += "<td style=\"color: red\">#{payment[member]}</td>"
      elsif payment[member] == payment_max
        result += "<td style=\"color: green\">#{payment[member]}</td>"
      else
        result += "<td>#{payment[member]}</td>"
      end

      result += "<td>#{work_month[member]/12}</td>"

      result += "</tr>"
      result += "\n"
    end

    result += "</table>\n"

    result
  end
end
