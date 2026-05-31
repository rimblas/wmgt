/**
  * Main namespace for wmgt.
  *
  * @namespace
  */
 var wmgt = {};


/**
 * @namespace
 */
// The wmgt.convert namespace is used for number conversion and formatting related functions

wmgt.convert = {};

( function( convert ) {
    "use strict";

    /**
     * Parses a string and returns an integer number
     *
     * @param  {String} v
     * @return {Number}  Integer number
     *
     * @function to_number
     * @memberOf wmgt.convert
     */
    convert.to_number = function(v) {
      let n = parseInt(v);
      return  isNaN(n) ? 0 : n;
    }


})( wmgt.convert );



wmgt.theme = {};
/**
 * @namespace
 */
// The wmgt.theme namespace is used general UI functions

( function( theme ) {
    "use strict";

    var mmWindowFocused = true,
        mmRefreshCompleted = [];


    /* Initialize Theme */
    theme.init = function() {
        /* get tooltips going */
        $(".tooltip").tooltip();
    },


    /* setInlineHelp: Sets the help message below an item */
    theme.setInlineHelp = function(itemID, msg) {
      let itemWrapper = apex.item(itemID).element.parents(".t-Form-itemWrapper");
      let el$ = apex.jQuery('#' + itemID + '_inline_help');

      if (!el$.length) {
        // Need to append: <span class="t-Form-inlineHelp"><span id="{itemID}_inline_help"></span></span>
        var out = apex.util.htmlBuilder();
        out.markup( "<span" )
            .attr( "class", "t-Form-inlineHelp" )
            .markup( "><span" )
            .attr( "id", itemID + "_inline_help" )
            .markup( "></span></span>" );

        itemWrapper.after(out.toString());
        
        el$ = apex.jQuery('#' + itemID + '_inline_help');
      }

      el$.html(msg);
    }

    // PRIVATE
    // Called by continuousReportRefresh
    theme._startIntervalRefreshReport = function (regionID, refreshEnabledItem) {
      var activeRefresh = true;
      if (typeof refreshEnabledItem == "undefined") {
        activeRefresh = true;
      }
      else {
        try {
            // test the item to see if the refresh calls should continue
            activeRefresh = $v(refreshEnabledItem) === "Y";
        }
        catch(e) {
            activeRefresh = true;
        }
      }
      if (mmWindowFocused && mmRefreshCompleted[regionID] && activeRefresh) {
         // if the window has focus, the previous refresh completed and we want 
         // to continue refreshing (activeRefresh) then go ahead and refresh
         mmRefreshCompleted[regionID] = false;  // clear so we detect that the session is still active
         apex.region(regionID).refresh();
      }
    },
  


    /*
    * Refresh a region indefinitely, but stop refreshing when the browser tab
    * is not visible any more
    *
    * "visibility change" Technique borrowed from:
    * https://stackoverflow.com/questions/7389328/detect-if-browser-tab-has-focus
    *
    * Examples
    * wmgt.theme.continuousReportRefresh("jobsRegion", 500, "P1_REFRESH_IND");
    * wmgt.theme.continuousReportRefresh("jobsRegion", 500);
    *
    * @author Jorge Rimblas
    * @created February 17, 2022
    * @param regionID: Static ID
    * @param interval: Milliseconds between refreshes
    * @param refreshEnabledItem [Optional]: A Y/N APEX Item that when Y will continue with the autorefresh
    */
    theme.continuousReportRefresh = function(regionID, interval, refreshEnabledItem) {
        mmRefreshCompleted[regionID] = true; // default the refresh region to complete so it can refresh again
        const intervalReport = setInterval(wmgt.theme._startIntervalRefreshReport, interval, regionID, refreshEnabledItem);

        mmWindowFocused = true;
        document.addEventListener("visibilitychange", function() {
            // detect when the window is not visible any more
            if (document.visibilityState === 'visible') {
                mmWindowFocused = true;
            } else {
                mmWindowFocused = false;
            }
        });

        mmRefreshCompleted[regionID] = true;
        // after each refresh we indicate the refresh has completed
        // when the session expires the `apexafterrefresh` event will never happen
        apex.jQuery( "#" + regionID ).on( "apexafterrefresh", function() {
            // detect if the latest apexafterrefresh happen, if it didn't
            // it could indicate to an expired session or error
            mmRefreshCompleted[regionID] = true;
        });

        return intervalReport;
    },


/* Week LOV Template */
theme.weekLovTemplate = function (options) {
    options.display = "grid";

    options.recordTemplate = (
  '<li data-id="~WEEK.">' +
     '<div class="content-list">' +
        '<div class="week-info-list">' +
           '<span class="season-name">~SEASON.</span>' +
           '<span class="week-name">Week ~WEEK_NO.</span>' +
           '<hr>' +
           '<div class="courses">' +
             '<span class="easy">~EASY_COURSE.</span>' + ' & ' +
             '<span class="hard">~HARD_COURSE.</span>' +
           '</div>' +
        '</div>' +
     '</div>'+
  '</li>').replace(/~/g, "&");

    return options;
},




/**
 * Static pie charts
 *
 * {@link http://dabblet.com/gist/66e1e52ac2a44ad87aa4}
 * By Lea Verou
 * @param selector {DOMelement} selector for the pie
 */
theme.renderPies = function (selector) {
  $(selector).each(function(index) {
    var p = this.textContent;
    this.style.animationDelay = '-' + parseFloat(p) + 's';
  });
}


})( wmgt.theme );



/**
 * Search helpers for matching plain text against styled Unicode text.
 *
 * @namespace
 */
window.wmgSearch = {};

( function( search ) {
  "use strict";

  /**
   * Normalize compatibility characters and letter case for searching.
   *
   * @param  {String} value
   * @return {String}
   */
  search.fold = function(value) {
    return String(value || "").normalize("NFKC").toLocaleLowerCase();
  };

  /**
   * Return mark.js ranges for a normalized search term while preserving the
   * offsets of the original display text.
   *
   * @param  {String} text
   * @param  {String} searchTerm
   * @return {Array}
   */
  search.nfkcRanges = function(text, searchTerm) {
    var normalizedText = ""
      , offsetMap = []
      , sourceOffset = 0
      , normalizedTerm = search.fold(searchTerm)
      , ranges = []
      , index;

    if (!normalizedTerm) {
      return ranges;
    }

    for (const character of text) {
      const normalizedCharacter = search.fold(character);

      normalizedText += normalizedCharacter;

      for (let i = 0; i < normalizedCharacter.length; i++) {
        offsetMap.push({
          start: sourceOffset,
          end: sourceOffset + character.length
        });
      }

      sourceOffset += character.length;
    }

    index = normalizedText.indexOf(normalizedTerm);

    while (index !== -1) {
      const first = offsetMap[index];
      const last = offsetMap[index + normalizedTerm.length - 1];

      if (first && last) {
        ranges.push({
          start: first.start,
          length: last.end - first.start
        });
      }

      index = normalizedText.indexOf(normalizedTerm, index + normalizedTerm.length);
    }

    return ranges;
  };

})( window.wmgSearch );
