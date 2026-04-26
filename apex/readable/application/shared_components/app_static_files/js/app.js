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
