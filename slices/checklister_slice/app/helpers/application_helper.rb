module Merb
  module ChecklisterSlice
    module ApplicationHelper
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def image_path(*segments)
        public_path_for(:image, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def javascript_path(*segments)
        public_path_for(:javascript, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def stylesheet_path(*segments)
        public_path_for(:stylesheet, *segments)
      end
      
      # Construct a path relative to the public directory
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def public_path_for(type, *segments)
        ::ChecklisterSlice.public_path_for(type, *segments)
      end
      
      # Construct an app-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the host application, with added segments.
      def app_path_for(type, *segments)
        ::ChecklisterSlice.app_path_for(type, *segments)
      end
      
      # Construct a slice-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the slice source (Gem), with added segments.
      def slice_path_for(type, *segments)
        ::ChecklisterSlice.slice_path_for(type, *segments)
      end
      def date_select(name, date = Date.today, opts={})
        # defaults to Date.today
        # should refactor
        attrs = {}
        attrs.merge!(:name => name)
        attrs.merge!(:date => date)
        attrs.merge!(:id => opts[:id]||name)
        attrs.merge!(:date => date)
        attrs.merge!(:size => opts[:size]||20)
        attrs.merge!(:min_date => opts[:min_date]||Date.min_date)
        attrs.merge!(:max_date => opts[:max_date]||Date.max_date)
        attrs.merge!(:nullable => (attrs.key?(:nullable) ? attrs[:nullable] : Mfi.first.date_box_editable))
        date_select_html(attrs)
      end

      def date_select_earliest(name, opts={})
        date_select(name, Constants::Time::EARLIEST_DATE_OF_OPERATION, opts)
      end

      def date_select_for(obj, col = nil, attrs = {})
        klass = obj.class
        attrs.merge!(:name => "#{klass.to_s.snake_case}[#{col.to_s}]")
        attrs.merge!(:id => "#{klass.to_s.snake_case}_#{col.to_s}")
        attrs[:nullable] = (attrs.key?(:nullable) ? attrs[:nullable] : Mfi.first.date_box_editable)
        date = attrs[:date] || obj.send(col)
        date = Date.today if date.blank? and not attrs[:nullable]
        date = nil if date.blank? and attrs[:nullable]
        attrs.merge!(:date => date)
        if TRANSACTION_MODELS.include?(klass) or TRANSACTION_MODELS.include?(klass.superclass) or TRANSACTION_MODELS.include?(klass.superclass.superclass)
          attrs.merge!(:min_date => attrs[:min_date]||Date.min_transaction_date)
          attrs.merge!(:max_date => attrs[:max_date]||Date.max_transaction_date)
        else
          attrs.merge!(:min_date => attrs[:min_date]||Date.min_date)
          attrs.merge!(:max_date => attrs[:max_date]||Date.max_date)
        end
        date_select_html(attrs, obj, col)
        #       errorify_field(attrs, col)
      end

      def date_select_html (attrs, obj = nil, col = nil)
        str = %Q{
        <input type='text' name="#{attrs[:name]}" id="#{attrs[:id]}" value="#{attrs[:date]}" size="#{attrs[:size]}" #{attrs[:nullable] ? "" : "readonly='true'"}>
        <script type="text/javascript">
          $(function(){
            var holidays= #{$holidays_list.to_json};
        function nonWorkingDays(date) {
        for (var j = 0; j < holidays.length; j++) {
        if (date.getMonth() == holidays[j][1] - 1 && date.getDate() == holidays[j][0] && date.getYear() - 100 == holidays[j][2]) {
        return [true, 'holiday_indicator'];
        }
        }
        return [true, ''];
        }
        $("##{attrs[:id]}").datepicker('destroy').datepicker({beforeShowDay: nonWorkingDays, altField: '##{attrs[:id]}', buttonImage: "/images/calendar.png", changeYear: true, buttonImageOnly: true,
        yearRange: '#{attrs[:min_date].year}:#{attrs[:max_date].year}',
        dateFormat: '#{datepicker_dateformat}', altFormat: '#{datepicker_dateformat}', minDate: '#{attrs[:min_date]}',
        maxDate: '#{attrs[:max_date]}', showOn: 'both', setDate: "#{attrs[:date]}" })
          });

       </script>
        }
        return str
      end
      
    end


  end
end