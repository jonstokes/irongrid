Stretched::Extension.define do
  extension "normalization" do

    def normalize_caliber(text)
      str = " #{text} "

      #
      # Normalize suffixes

      #+P variants
      str.gsub!(/(\d|\w)\+p/i) do |match|
        match.sub!(/\+p/i, " +P")
      end

      # S&W
      str.gsub!(/(\.|\s)(32|38|40|44|460|500)\s{0,1}(s\&w|smith \& wesson|smith and wesson|s \& w|s and w|sw)\.?\,?\s+/i) do |match|
        match.sub!(/s\&w|smith \& wesson|smith and wesson|s \& w|s and w|sw/i, " S&W")
      end
      str.squeeze!(" ")

      # H&R
      str.gsub!(/(\.|\s)32\s{0,1}(h\&r|h & r|h and r|hr)\.?\,?\s+/i) do |match|
        match.sub!(/h\&r|h & r|h and r|hr/i, " H&R")
      end
      str.squeeze!(" ")

      # Rem
      str.gsub!(/(\.|\s)(357|mm|6\.8|6\.5|416|35|350|300|30|223|280|260|25(\s|\-)06|222|17|41)\s{0,1}(remington|rem)\.?\,?\s+/i) do |match|
        match.sub!(/remington|rem|rem\./i, " Rem")
      end
      str.squeeze!(" ")

      # Win
      str.gsub!(/(\.|\s)(38(\-|\s)40|45|300|308)\s{0,1}(winchester|win)\.?\,?\s+/i) do |match|
        match.sub!(/winchester|win|win\./i, " Win")
      end
      str.squeeze!(" ")

      # Magnum
      str.gsub!(/(\.|\s)(32|327|357|41|44|445|45|460|475|500|300).{0,6}(mag|magnum)\.?\,?\s+/i) do |match|
        match.sub!(/(magnum|mag\.{0,1})/i, " Mag")
      end
      str.squeeze!(" ")

      # WSM
      str.gsub!(/(\.|\s)(270|300|325|benchrest|mm|7mm|17)\s{0,1}(winchester short mag)\.?\,?\s+/i) do |match|
        match.sub!(/(winchester short mag\.{0,1})/i, " WSM")
      end
      str.squeeze!(" ")

      # Special
      str.gsub!(/(\.|\s)(38|s\&w)\s{0,1}(special|spcl|spl|spc|sp)\.?\,?\s+/i) do |match|
        match.sub!(/special|spcl|spl|spc|sp/i, " Special")
      end
      str.squeeze!(" ")

      # Super
      str.gsub!(/(\.|\s)(38|45|445)\s{0,1}(super|sup|spr)\.?\,?\s+/i) do |match|
        match.sub!(/super|sup|spr/i, " Super")
      end
      str.squeeze!(" ")

      # Cor-Bon
      str.gsub!(/(\.|\s)(440|400)\s{0,1}(cor-bon|corbon|cor bon)\.?\,?\s+/i) do |match|
        match.sub!(/cor-bon|corbon|cor bon/i, " Cor-Bon")
      end
      str.squeeze!(" ")

      # Mini mag
      str.gsub!(/(\.|\s)(22|lr|lrhp|hp|long rifle)\s{0,1}(mini-mag|mini mag)\.?\,?\s+/i) do |match|
        match.sub!(/mini-mag|mini mag/i, " Mini Mag")
      end
      str.squeeze!(" ")

      # 9x18 etc.
      str.gsub!(/(\.|\s)(6|7|2|3|5|8|9)\s{0,1}x\s{0,1}(30|28|25|38|21|22|23|25|18|19)\.?\,?\s+/i) do |match|
        match.sub!(/\s{0,1}x\s{0,1}/i, "x")
      end
      str.squeeze!(" ")

      # Millimeter
      str.gsub!(/(\.|\s)(30|75|28|35|25|21|8|9|10|22|18|23)\s{0,1}(mm|millimeter|milimeter|mil)\.?\,?\s+/i) do |match|
        match.sub!(/mm|millimeter|milimeter|mil/i, " mm")
      end
      str.squeeze!(" ")
      str.gsub!(/(\.|\s)(30|75|28|35|25|21|8|9|10|22|18|23)\s{0,1}(mm|millimeter|milimeter|mil)\.?\,?\s+/i) do |match|
        match.gsub!(/\smm/i,"mm")
      end
      str.squeeze!(" ")

      # Gauge
      str.gsub!(/(\.|\s)(10|12|16|20|24|28|32|410)(\s{0,1}|\-)(gauge|guage|ga|g)\.?\,?\s+/i) do |match|
        match.sub!(/(\s{0,1}|\-)(gauge|guage|ga|g)/i, " gauge")
      end

      str.strip.squeeze(" ")

      #
      # Normalize dots

      # Pre-caliber dot with dashes
      str.gsub!(/\s(25|250|30|38|338|40|44|45|450|50|56|577)(\s|\-)\d{1,3}/) do |match|
        i = match.index(/\d{2,3}(\s|\-)\d{1,3}/i)
        match = match.insert(i,".")
      end

      # Pre-caliber dot 200's
      str.gsub!(/\s(17|22|25 acp|25 naa|22[01345]|240|243|257|260|264|270|275|280|284)\s/i) do |match|
        i = match.index(/\d{2,3}\s/)
        match = match.insert(i,".")
      end

      # Pre-caliber dot 300's
      str.gsub!(/\s(30\s?\-?ma(u|us|user)?|30[0378]|318|32|325|327|333|338|340|348|35|35[0168]|357|370|375|378|38|380)\s/i) do |match|
        i = match.index(/30\s?\-?ma(u|us|user)?|\d{2,3}\s/i)
        match = match.insert(i,".")
      end

      # Pre-caliber dot 400's
      str.gsub!(/\s(40\s(s&w|super)|(4[145]|400)\s?\-?[capn][\w\-]{1,7}|404|405|416|426|440|445|450|454|455|458|460|470|475|480)\s/i) do |match|
        i = match.index(/40\s(s&w|super)|4[145]|400\s?\-?[capn](\w{1,6}|\-)|\d{3}\s/i)
        match = match.insert(i,".")
      end

      # Pre-caliber dot 500's
      str.gsub!(/\s(50\s?\-?[bmgeiac]{2}\w{0,5}|500\s?\-?[ajnlsw][a-z&\s\-]{1,16}|505|510)\s/i) do |match|
        i = match.index(/50\s?\-?[bmgeiac]{2}\w{0,5}|500\s?\-?[ajnlsw][a-z&\s\-]{1,16}|505|510\s/i)
        match = match.insert(i,".")
      end
      str.strip.squeeze(" ")
    end

  end
end
