Stretched::Extension.define "ironsights/extensions/extraction" do
  extension do
    def extract_bullet_type(text)
      return unless text.present?
      boat_tail = text[/boat\Wtail|\Wbt/i]
      hollow_point = text[/hollow point|\Whp\W/i]
      fmj = text[/full\Wmetal\Wjacket(ed)?|fmj/i]

      return 'FMJBT' if (fmj && boat_tail) || text[/fmjbt/i]
      return 'JHP' if text[/jhp|jacket(ed)?\Whollow\Wpoint|jacket(ed)?\Wh(\W)?p/i]
      return 'JFP' if text[/jhp|jacket(ed)?\Wflat\Wpoint|jacket(ed)?\Wf(\W)?p/i]
      return 'JSP' if text[/jhp|jacket(ed)?\Wsoft\Wpoint|jacket(ed)?\Ws(\W)?p/i]
      return 'JRN' if text[/jhp|jacket(ed)?\Wround\Wnose|jacket(ed)?\Wr(\W)?n/i]
      return 'BTHP' if hollow_point && boat_tail
      return 'BTSP' if text[/btsp|spbt/i] || text[/soft\Wpoint/i] && boat_tail
      return 'EFMJ' if text[/efmj|expanding\Wfmj/i] || text[/exp(anding)?/i] && fmj
      return 'SWC' if text[/swc|semi\Wwad\Wcutter/i]
      return 'WC' if text[/\Wwc|wad\Wcutter/i]
      return 'RFP' if text[/\Wrfp|rounded\Wflat\Wp(oi)?nt/i]
      return 'API' if text[/\WAPI\W/] || text[/\WAP\W/] && text[/incendiary/i]
      return 'AP' if text[/\WAP\W/] || text[/armor\Wp[ie]{2}rcing/i]
      return 'FRNG' if text[/fr(a)?ng(i)?(bl)?(e)?/i]
      return 'FMJ' if fmj || text[/metal\Wcase(d)?/i] || text[/\WMC\W/]
      return 'HP' if hollow_point
      return 'BT' if boat_tail
      return 'RN' if text[/round\Wnose/i]
      nil
    end

    def extract_grains(text)
      return unless text.try(:present?)
      str = " #{text} "
      return unless grains = str[/\d+(\s{0,1}|\-)(gr|grn|grain)s?\.?\,?\s+/i]
      grains = grains[/\d+/]
      grains.present? ? grains : nil
    end

    def extract_number_of_rounds(text)
      return unless text.try(:present?)
      str = " #{text} "
      return unless rounds = str[/[0-9]+(\,[0-9]+)?\W{0,3}ro?u?n?ds?/i] ||
        str[/box\s+of\s+[0-9]+(\,[0-9]+)?\W/i] ||
        str[/[0-9]+(\,[0-9]+)?\W{0,3}(per|\/)\s?bo?x/i]
      r = rounds[/[0-9]+(\,[0-9]+)?/]
      r.present? ? r.delete(",") : nil
    end

    def extract_metadata(source_attribute, mapping, instance)
      unless tokens = instance["#{source_attribute}_tokens"]
        text = instance[source_attribute]
        return unless text.present?
        text = normalize_caliber(text)
        tokens = mapping.tokenize(text)
      end

      if result = mapping.analyze(tokens)
        instance["#{source_attribute}_tokens"] = result[:tokens]
        result[:term]
      else
        nil
      end
    end
  end
end
