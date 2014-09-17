Stretched::Extension.define do
  extension "normalization" do
    def normalize_caliber(text)
      str = " #{text} "

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
      str.gsub!(/(\.|\s)(357|mm|6\.8|6\.5|416|35|350|300|30|280|260|25(\s|\-)06|222|17|41)\s{0,1}(remington|rem)\.?\,?\s+/i) do |match|
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

    end

  end
end
