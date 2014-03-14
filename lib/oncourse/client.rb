require 'mechanize'
module Oncourse
  URLS = {
    main: "http://www.oncoursesystems.com/",
    set_planner: "http://www.oncoursesystems.com/planner/planner_frame.aspx", #date=20140310&user_id=user_id&template=N
    get_planner: "http://www.oncoursesystems.com/planner/planner.aspx",
    close_planner: "http://www.oncoursesystems.com/planner/planner_navigation_bar.aspx", #action=C&tabid=337113074
    lesson_standards: "http://www.oncoursesystems.com/json.axd/lessonplan/references_linked", #post request, {id: <standards_id>}
    link_standards: "http://www.oncoursesystems.com/json.axd/standards/link_standards",
    read_standard_areas: "http://www.oncoursesystems.com/json.axd/standards/lesson_standard_areas", #post request, {setId: <standard_setId}
    lesson_standard_filters: "http://www.oncoursesystems.com/json.axd/standards/lesson_standard_filters", #post request, {setId: <standard_setId>, subject: {standard_subject}}
    lesson_standards_tree: "http://www.oncoursesystems.com/json.axd/standards/lesson_standards_tree",
    read_lesson: "http://www.oncoursesystems.com/json.axd/LessonPlan/lesson_record",
    post_lesson: "http://www.oncoursesystems.com/json.axd/LessonPlan/lesson_record_save",
    lesson_tree: "http://www.oncoursesystems.com/json.axd/LessonPlan/lesson_tree" #{userId: <user_id>}
  }
  class Client
    attr_accessor :mech, :user_id, :weeks, :request_rate, :lesson_tree

    # create new mechanize object and go through login steps
    def initialize(username,password,request_rate=1)
      @request_rate = request_rate
      @mech = Mechanize.new()
      login_page = @mech.get(URLS[:main])
      login_form = login_page.forms.first
      login_form.Username = username
      login_form.Password = password.strip
      home_page = login_form.submit
      script_tag = home_page.parser.search("script").select{|s| s.text.index('user_id')}.first
      raise "Login failed, script_tag not present." unless script_tag
      @user_id = /\"user_id\":\"([0-9]+)\"/.match(script_tag.text).captures.first
      raise "Login failed, unable to find user_id" unless @user_id
    end

    # read lesson planner for current user starting at start_Date: start_date
    # and going each week up to num_weeks
    def read_planner(start_date, num_weeks)
      @weeks = []
      start = start_date
      cell_ids = 0
      itr = 0
      num_weeks.times do
        start += itr * 7
        week = {start: start.strftime("%Y%m%d")}
        week[:columns] = []

        # a get request to this set_planner url sets the current viewed planner
        @mech.get(URLS[:set_planner], {date: week[:start], user_id: @user_id, template:'N'})
        rate_pause()

        planner_frame = @mech.get(URLS[:get_planner])

        # parse out column headers
        columns = planner_frame.parser.search("tr.sheetRowHeader th:not(.sheetRow1stCell)").each_with_index.map{|cell, idx| {label: cell.text.strip, period: idx + 1}}

        # parse out each cell, ids give date and period.
        # Period corresponds to column number.
        # .lessonPreview classes contain the markup and content created by ext3's text editor
        # that teachers use to input lessons.
        cells = planner_frame.parser.search(".sheetCell")
        cells = cells.map do |cell|
          cell_hash = {
            date: cell['id'][0...-2],
            period: cell['id'][-2..-1].to_i,
            html: cell.search('.lessonPreview').first.inner_html
          }
          flag_element = cell.search('.sheetCellIcons img[src="/images/icons/flag_blue.png"]').first
          if(flag_element)
            match = /showStandard\(\'([0-9]+)\'\)/.match(flag_element['onclick'])
            if(match && match.captures.first)
              cell_hash[:standards_id] = match.captures.first
            end
          end
          cell_hash
        end
        columns.each do |column|
          column[:cells] = cells.select{|cell| cell[:period] == column[:period]}
        end

        week[:columns] = columns

        @weeks << week
        itr += 1
        rate_pause()
      end

      return @weeks
    end

    def rate_pause
      sleep((1 + rand(0.1)) * @request_rate)
    end

    def read_planner_standards()
      raise "planner weeks empty" if !@weeks || @weeks.length == 0
      keys = ["id", "header_name", "detail_name"]
      @weeks.each do |week|
        week[:columns].each do |column|
          column[:cells].each do |cell|
            next unless cell[:standards_id]

            json_response = @mech.post(URLS[:lesson_standards], {
              id: cell[:standards_id]
            })

            cell[:standards] = JSON.parse(json_response.content).map{|f| f.reject{|k,v| !keys.include?(k)}}
            rate_pause()
          end
        end
      end
      return @weeks
    end

    def save_planner(filename)
      File.open(filename, "w") { |f| f.puts JSON.pretty_generate(@weeks)}
    end

    # method to read one lesson through the json interface
    # This is required before posting a lesson since it's the only way to get the
    # homework field that I've found.  If you post an empty homework field, any previous
    # homework entry will be lost
    def read_lesson(date, period)
      response = @mech.post(URLS[:read_lesson], {
        userId: @user_id,
        date: date.strftime("%m/%d/%Y"),
        period: period
      })
      return JSON.parse(response.content)["ReturnValue"]
    end

    def read_lesson_tree()
      return @lesson_tree if @lesson_tree
      response = @mech.post(URLS[:lesson_tree], {userId: @user_id})

      # oncourse returns invalid JSON, using this ugly regex for now.
      fixed_json = fix_malformed_json(response.content)

      @lesson_tree = JSON.parse(fixed_json)

      return @lesson_tree
    end

    # oncourse produces a lot of malformed json.  It seems to strip the quotes off strings
    # on deeply nested objects.  Not sure what they're doing wrong, since I don't think
    # the problem is with ext3
    def fix_malformed_json(malformed_json)
      return malformed_json.gsub(/([a-z][a-zA-Z0-9_]+):(?!\s)/, '"\1":')
    end

    # read parent groups for standards
    def read_standard_groups()
      read_lesson_tree unless @lesson_tree

      #have to traverse a big json tree here
      standards_branch = @lesson_tree.find{|branch| branch["text"] == "Standards"}
      return standards_branch["children"].map do |child|
        {
          label: child["text"],
          set_id: child["xconfig"]["setId"]
        }
      end
    end

    # reads first child group of standards
    def read_standard_areas(set_id)
      response = @mech.post(URLS[:standard_areas], {setId: set_id})

      return JSON.parse(fix_malformed_json(response.content))
    end

    # reads filters that must be applied after selecting first child group
    def read_lesson_standard_filters(set_id, subject)
      response = @mech.post(URLS[:lesson_standard_filters], {setId: set_id, subject: subject})

      return JSON.parse(response.content)
    end

    # Reads a full list of standards for a given SetID, subject, grade, and year
    def read_lesson_standards_tree(set_id, subject, grade, year)
      response = @mech.post(URLS[:lesson_standards_tree], {
        userId: @user_id,
        setId: set_id,
        subject: subject,
        yearName: year,
        searchText1: "",
        searchOperator: "",
        searchText2: "",
        powerSetID: "",
        mapID: "",
        grade: grade,
        showOnlyPowerSet: false,
        activityDate: Date.today.strftime("%m/%d/%Y"), # seems arbitrary
        activityPeriod: 1 # arbitrary
      })

      return JSON.parse(response.content)
    end

    def link_standard(standard_id, date, period)
      response = @mech.post(URLS[:link_standards], {
        objectType: "L",
        id: standard_id,
        date: date.strftime("%m/%d/%Y"),
        period: period,
        link: true
      })

      return JSON.parse(response.content)
    end

    def unlink_standard(standard_id, date, period)
      response = @mech.post(URLS[:link_standards], {
        objectType: "L",
        id: standard_id,
        date: date.strftime("%m/%d/%Y"),
        period: period,
        link: false
      })

      return JSON.parse(response.content)
    end

    # This method will absolutely overwrite anything that occupies this place
    # in the lesson plan.  To play it safe, one should call read_lesson and store
    # that response somewhere before using post lesson.  This way there is a backup
    # of previous work.  Oncourse does not appear to keep a revision history on
    # lesson plans.
    def post_lesson(lesson, homework, date, period)
      response = @mech.post(URLS[:post_lesson], {
        userId: @user_id,
        date: date.strftime("%m/%d/%Y"),
        period: period,
        notes: lesson,
        homework: homework
      })
      return response
    end
  end
end
