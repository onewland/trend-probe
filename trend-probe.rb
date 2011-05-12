require 'httparty'
require 'pp'
require 'launchy'
require 'gtk2'

module TrendProbe
  module Util
    def self.load_trends_json
      HTTParty.get('http://api.twitter.com/1/trends.json')
    end
  end
  
  class AppWindow < Gtk::Window
    TREND_NAME_COLUMN = 0
    TREND_SEARCH_URL = 1
    TREND_HIGHLIGHT = 2
    def load_trends
      Util.load_trends_json.each do |result|
        if result.length > 1 && result[0] == 'trends'
          result[1].each do |t|
            @trends << t
          end
        end
      end
    end

    def update_data_store
      @data_store.clear
      @trends.each_with_index do |trend, i|
        iter = @data_store.append
        @data_store.set_value(iter, TREND_NAME_COLUMN, trend['name'])
        @data_store.set_value(iter, TREND_SEARCH_URL, trend['url'])
        @data_store.set_value(iter, TREND_HIGHLIGHT, 0)
      end
    end

    def load_trends_and_update_data_store
      @trends = []
      load_trends
      update_data_store
    end

    def open_in_browser
      iter = @selector.selected
      Launchy.open(iter[TREND_SEARCH_URL])
    end

    def highlight_callback
      iter = @selector.selected
      hl_value = iter[TREND_HIGHLIGHT]
      hl_value += 1 
      hl_value = 0 if hl_value > 2
      @data_store.set_value(iter, TREND_HIGHLIGHT, hl_value)
    end

    def init_buttons 
      @open_in_browser = Gtk::Button.new 'Open in browser'
      @open_in_browser.signal_connect('clicked') { open_in_browser }
      @highlight = Gtk::Button.new 'Highlight'
      @highlight.signal_connect('clicked') { highlight_callback }
    end

    def init_list_view
      @renderer = Gtk::CellRendererText.new
      @column = Gtk::TreeViewColumn.new('Trend', 
        @renderer, 
        'text' => TREND_NAME_COLUMN
      )
      @column.set_cell_data_func(@renderer) do |col, renderer, model, iter|
        if iter[TREND_HIGHLIGHT] == 1
          renderer.background = 'yellow'
        elsif iter[TREND_HIGHLIGHT] == 2
          renderer.background = 'green'
        else
          renderer.background = nil
        end
      end
      @list_view = Gtk::TreeView.new
      @list_view.append_column @column
      @data_store = Gtk::ListStore.new(String, String, Integer)
      @list_view.model = @data_store
      @selector = @list_view.selection
    end

    def initialize(t = "Trends")
      super
      self.title = t

      init_list_view
      init_buttons

      @trends = []

      @main_box = Gtk::VBox.new
      @main_box.add @list_view
      @main_box.add @open_in_browser
      @main_box.add @highlight
      self.add @main_box
      self.load_trends_and_update_data_store
      Gtk.timeout_add(5 * 60 * 1000) do
         self.load_trends_and_update_data_store
      end
    end
  end

  def self.main(args)
    window = AppWindow.new
    window.signal_connect('delete_event') { Gtk.main_quit }
    window.show_all
    Gtk.main
  end
end

TrendProbe.main(ARGV)
