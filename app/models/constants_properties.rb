module Constants
  module Properties

    MEDIUM_STRING_LENGTH = 255
    NOT_NULL          = { :nullable => false }
    UNIQUE            = { :unique => true }

    INTEGER_NOT_NULL  = [ Integer, NOT_NULL ]
    FLOAT_NOT_NULL    = [ Float, NOT_NULL ]
    DATE              = [ Date ]
    DATE_NOT_NULL     = [ Date, NOT_NULL ]

    NAME              = [ String, { :length => MEDIUM_STRING_LENGTH }.merge(NOT_NULL) ]
    UNIQUE_NAME       = [ String, { :length => MEDIUM_STRING_LENGTH }.merge(NOT_NULL).merge(UNIQUE) ]
    TENURE            = [ Integer, { :min => 1 }.merge(NOT_NULL) ]
    COUNTER           = [ Integer, { :min => 1 }.merge(NOT_NULL) ]
    INSTALLMENT       = [ Integer, { :min => 0 }.merge(NOT_NULL) ]

    MONEY_AMOUNT_PRECISION = 65; MONEY_AMOUNT_SCALE = 0; MONEY_AMOUNT_MINIMUM = 0
    MONEY_AMOUNT_NULL = [ BigDecimal, { :precision => MONEY_AMOUNT_PRECISION, :scale => MONEY_AMOUNT_SCALE, :min => MONEY_AMOUNT_MINIMUM } ]
    MONEY_AMOUNT      = [ BigDecimal, { :precision => MONEY_AMOUNT_PRECISION, :scale => MONEY_AMOUNT_SCALE, :min => MONEY_AMOUNT_MINIMUM }.merge(NOT_NULL) ]
    UNIQUE_ID_STRING_LENGTH = 40
    UNIQUE_ID         = [ String, { :length => UNIQUE_ID_STRING_LENGTH, :default => lambda {|obj, p| UUID.generate} }.merge(NOT_NULL).merge(UNIQUE) ]

    TIMESTAMP         = { :default => DateTime.now }
    CREATED_AT        = [ DateTime, TIMESTAMP.merge(NOT_NULL) ]
    UPDATED_AT        = CREATED_AT
    DELETED_AT        = [ DataMapper::Types::ParanoidDateTime ]

    FREQUENCY         = [ DataMapper::Types::Enum.send('[]', *MarkerInterfaces::Recurrence::FREQUENCIES), NOT_NULL ]
    CURRENCY          = [ DataMapper::Types::Enum.send('[]', *Constants::Money::CURRENCIES), NOT_NULL ]
  end
end
