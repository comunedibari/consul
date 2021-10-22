class CodiceFiscaleValidator < ActiveModel::EachValidator

  CHECK_CODE_ODD = Hash[
      "0" => 1,
      "1" => 0,
      "2" => 5,
      "3" => 7,
      "4" => 9,
      "5" => 13,
      "6" => 15,
      "7" => 17,
      "8" => 19,
      "9" => 21,
      "A" => 1,
      "B" => 0,
      "C" => 5,
      "D" => 7,
      "E" => 9,
      "F" => 13,
      "G" => 15,
      "H" => 17,
      "I" => 19,
      "J" => 21,
      "K" => 2,
      "L" => 4,
      "M" => 18,
      "N" => 20,
      "O" => 11,
      "P" => 3,
      "Q" => 6,
      "R" => 8,
      "S" => 12,
      "T" => 14,
      "U" => 16,
      "V" => 10,
      "W" => 22,
      "X" => 25,
      "Y" => 24,
      "Z" => 23
  ]

  CHECK_CODE_EVEN = Hash[
      "0" => 0,
      "1" => 1,
      "2" => 2,
      "3" => 3,
      "4" => 4,
      "5" => 5,
      "6" => 6,
      "7" => 7,
      "8" => 8,
      "9" => 9,
      "A" => 0,
      "B" => 1,
      "C" => 2,
      "D" => 3,
      "E" => 4,
      "F" => 5,
      "G" => 6,
      "H" => 7,
      "I" => 8,
      "J" => 9,
      "K" => 10,
      "L" => 11,
      "M" => 12,
      "N" => 13,
      "O" => 14,
      "P" => 15,
      "Q" => 16,
      "R" => 17,
      "S" => 18,
      "T" => 19,
      "U" => 20,
      "V" => 21,
      "W" => 22,
      "X" => 23,
      "Y" => 24,
      "Z" => 25
  ]

  CHECK_CODE_REMAINDER = Hash[
      0 => 'A',
      1 => 'B',
      2 => 'C',
      3 => 'D',
      4 => 'E',
      5 => 'F',
      6 => 'G',
      7 => 'H',
      8 => 'I',
      9 => 'J',
      10 => 'K',
      11 => 'L',
      12 => 'M',
      13 => 'N',
      14 => 'O',
      15 => 'P',
      16 => 'Q',
      17 => 'R',
      18 => 'S',
      19 => 'T',
      20 => 'U',
      21 => 'V',
      22 => 'W',
      23 => 'X',
      24 => 'Y',
      25 => 'Z'
  ]

  FORMAT_NO_CHECK_DIGIT = /([A-Z]{6})([\dL-V]{2})([ABCDEHLMPRST])([\dL-V]{2})([A-Z][\dL-V]{3})/
  REGEX = /#{FORMAT_NO_CHECK_DIGIT}([A-Z])/

  def validate_each(record, attribute, value)
    if !value.blank? and fiscal_code_validation(value)
      true
    else
      # TODO: il messaggio è hard-coded ma dovremmo metterlo in un .yml
      record.errors[attribute] << (options[:message] || "codice fiscale non valido")
      false
    end
  end

  private

  def regex_validation(fiscal_code)
    fiscal_code =~ REGEX
  end

  def control_code_validation(fiscal_code, control_char)
    control_char === control_code_calculation(fiscal_code)
  end

  def control_code_calculation(fiscal_code)
    cf_array = fiscal_code.split('')
    sum = 0

    cf_array[0..-2].each_with_index do |char, index|
      if index.even?
        sum += CHECK_CODE_ODD[char]
      else
        sum += CHECK_CODE_EVEN[char]
      end
    end

    remainder = sum % 26

    CHECK_CODE_REMAINDER[remainder]
  end

  def fiscal_code_validation(fiscal_code)
    fiscal_code = fiscal_code.upcase

    control_char = fiscal_code[-1, 1]

    (regex_validation(fiscal_code) && control_code_validation(fiscal_code, control_char))
  end

end
