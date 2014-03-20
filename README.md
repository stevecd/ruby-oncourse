# Oncourse

Oncoursesystems.com is a web app written in extjs that handles managing teacher
lesson plans amongst many other things.  It has proven to be incredibly tedious to
work with so I spent a day parsing its html and json requests involved with lessonplan
editing.  This gem is the result.

## Installation

Add this line to your application's Gemfile:

    gem 'oncourse'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oncourse

## Usage

    require 'oncourse'
    client = Oncourse::Client.new('testuser', 'password')

    # parse the weekly planner for a specific date and number of weeks.
    # in the school I'm helping, the weeks start on monday, so this date should
    # be a monday.  The week is that monday and the following 4 days.
    # This method only parses the html, so it does not read the homework field.
    # You'll only get the lesson.  Use client.read_lesson if you want the homework.
    lessonplan = client.read_planner(Date.parse("2014-03-10"), 1)

    # After a client.read_planner call, the planner is stored in an instance variable.
    # We can now read all of the standards for each lesson we've read so far:
    lessonplan_with_standards = client.read_planner_standards()
    

    # Save the lesson plan so far.
    client.save_planner("./lessonplan_20140310.json")

    # read a single lesson given a date and period.
    # this method also returns homework
    puts client.read_lesson(Date.today, 2)

    # post a lesson
    client.post_lesson("2 + 2 = 4", "homework: 3+3= ?", Date.today, 2)

## Contributing

1. Fork it ( http://github.com/stevecd/ruby-oncourse/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
