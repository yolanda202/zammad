ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test/unit'
require 'rubygems'
require 'selenium-webdriver'

class ExampleTest < Test::Unit::TestCase
    attr_reader :browser

    def setup
      @browser = Selenium::WebDriver.for :chrome
    end

    def teardown
        browser.quit
    end

    def test_first_page
        browser.get "http://portal.znuny.com/"
	assert_equal browser.current_url, "https://portal.znuny.com/#login"
    end

    def test_login_failed
       element_username = browser.find_element :name => "username"
       element_username.send_keys "roy@kaldung.de"
       element_password = browser.find_element :name => "password"
       element_password.send_keys "123456"
       element_form = browser.find_element :id => "login"
       element_form.submit
       assert_equal browser.current_url, "https://portal.znuny.com/#login"
    end

    def test_login_passed
       element_username = browser.find_element :name => "username"
       element_username.send_keys "roy@kaldung.com"
       element_password = browser.find_element :name => "password"
       element_password.send_keys "090504"
       element_form = browser.find_element :id => "login"
       element_form.submit
       assert_equal browser.current_url, "https://portal.znuny.com/#ticket_view/my_tickets"
    end

    def test_page_search
	browser.get "http://www.google.com"
        puts "Page title is #{browser.title}"
        assert_equal "Google", browser.title
    end
end


