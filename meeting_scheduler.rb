$week_table={
  Mon: 0,
  Tue: 1,
  Wed: 2,
  Thu: 3,
  Fri: 4
}

$time_table={
  "1000": 1,
  "1030": 2,
  "1100": 3,
  "1130": 4,
  "1200": 5,
  "1230": 6,
  "1300": 7,
  "1330": 8,
  "1400": 9,
  "1430": 10,
  "1500": 11,
  "1530": 12,
  "1600": 12,
  "1630": 12,
  "1700": 12
}

def maxof(a,b)
  if a < b
    b
  else
    a
  end
end

class Array
  def to_propositional_variable
    tmp_list = []
    self.each do |e|
      tmp_list << ((maxof($time_table[e[1].to_sym]-3,1)+$week_table[e[0].to_sym]*11)..($time_table[e[2].chop.to_sym]-1+$week_table[e[0].to_sym]*11)).to_a
    end
    tmp_list
  end
end

class Scheduler
  def initialize(filename)
    @cnf = []
    @input = []
    @list = (1..55).to_a
    @filename = filename
    @cls_count = 0
    @var_count = 55
    #ファイル読み込み 
    File.open(@filename,mode="rt"){|f|
      @input=f.readlines.map{|arr| arr.split(',')}
    }
    #p @list
  end

  def generate_CNF
    #デフォルトCNF
    #at-least-one
    s=""
    @list.each do |e|
      s += e.to_s + " "
    end
    s += 0.to_s
    @cnf.append(s)
    @cls_count += 1

    #at-most-one
    @list.combination(2).each do |e|
      @cnf.append("-" + e[0].to_s + " -" + e[1].to_s + " " + 0.to_s)
      @cls_count += 1
    end

    #インプットCNF
    @input.to_propositional_variable.each do |arr|
      arr.each do |e|
        @cnf.append("-" + e.to_s + " " + 0.to_s)
        @cls_count += 1
      end
    end

    File.open(@filename.gsub('txt','cnf'),mode="w"){|f|
      f.write("p cnf #{@var_count} #{@cls_count}\n")
      @cnf.each do |e|
        f.write(e + "\n")
      end
    }
  end

  def solve_CNF
    system("minisat #{@filename.gsub('txt','cnf')} output > /dev/null 2>&1")
  end

  def analysis_log
    output = []
    File.open("output",mode="rt"){|f|
      output=f.readlines.map{|arr| arr.split}
    }
    if output[0][0] == "UNSAT"
      puts "充足可能な日時は存在しません"
      exit
    end
    sat = nil
    output[1].each do |e|
      if e.to_i > 0
        sat=e.to_i
        break
      end
    end

    start_time = nil
    if $time_table.key(sat%11) == nil
      start_time = 1500
    else
      start_time = $time_table.key(sat%11)
    end

   puts "曜日 : #{$week_table.key((sat-1)/11)}
開始時刻 : #{start_time}
終了時刻 : #{start_time.to_s.to_i + 200}"
  end
end

meeting_scheduler = Scheduler.new(ARGV[0])
meeting_scheduler.generate_CNF
meeting_scheduler.solve_CNF
meeting_scheduler.analysis_log
