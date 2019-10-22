class TimeValidator < ActiveModel::EachValidator

    def validate_each(record, attribute, value)
        before_type_cast = record.attributes_before_type_cast[attribute.to_s]
        if before_type_cast.is_a?(String) && before_type_cast.present?
            unless before_type_cast =~ /\A\d{1,2}:\d{2}(:\d{2})?\z/ && value
                record.errors.add(attribute, :not_a_time)
            end
        end
    end

end
