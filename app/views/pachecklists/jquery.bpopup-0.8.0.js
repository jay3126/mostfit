/******************************************************************************************************************
 * @name: bPopup
 * @type: jQuery
 * @author: (c) Bjoern Klinggaard (http://dinbror.dk/bpopup) @bklinggaard
 * @version: 0.8.0
 * @requires jQuery 1.4.2
 * todo: refactor, onLoaded + recenter
 *******************************************************************************************************************/
;(function($) {
    $.fn.bPopup = $['bPopup'] = function(options, callback) {
        
		if ($.isFunction(options)) {
            callback 		= options;
            options 		= null;
        }

		// OPTIONS
        var o 				= $.extend({}, $.fn.bPopup.defaults, options);
        
		// HIDE SCROLLBAR?  
        if (!o.scrollBar)
            $('html').css('overflow', 'hidden');
        
		// VARIABLES	
        var $popup 			= this
        	, d 			= $(document)
        	, w 			= $(window)
        	, prefix		= '__bPopup'
			, isIOS6X		= (/OS 6(_\d)+/i).test(navigator.userAgent) // Used for a temporary fix for ios6 timer bug when using zoom/scroll 
        	, popups
        	, id
        	, inside
        	, fixedVPos
        	, fixedHPos
        	, fixedPosStyle
        	, cp
        	, vPos
        	, hPos;

		////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // PUBLIC FUNCTION - call it: $(element).bPopup().close();
		////////////////////////////////////////////////////////////////////////////////////////////////////////////
        $popup.close = function() {
            o = this.data('bPopup');
			id = prefix + w.data('bPopup')
            close();
        };

        return $popup.each(function() {
            if ($popup.data('bPopup')) return; //POPUP already exists?
            init();
        });

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // HELPER FUNCTIONS - PRIVATE
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        function init() {
            triggerCall(o.onOpen);
            popups = (w.data('bPopup') || 0) + 1, id = prefix + popups,fixedVPos = o.position[1] !== 'auto', fixedHPos = o.position[0] !== 'auto', fixedPosStyle = o.positionStyle === 'fixed';
            o.loadUrl ? createContent() : open();
        }
		function createContent() {
            o.contentContainer = $(o.contentContainer || $popup);
            switch (o.content) {
                case ('iframe'):
					$('<iframe id="bIframe" scrolling="no" frameborder="0"></iframe>').attr('src', o.loadUrl).appendTo(o.contentContainer);
					//$('#bIframe').load(function(){
					    triggerCall(o.loadCallback);
						open();
					//});
                    break;
                default:
                    o.contentContainer.load(o.loadUrl,function(){
						triggerCall(o.loadCallback);
						open();
					});
                    break;
            }
        }
		function open(){
			cp = getCenterPosition($popup, o.amsl),vPos = fixedVPos ? o.position[1] : cp[1],hPos = fixedHPos ? o.position[0] : cp[0],inside = insideWindow();
			
			// MODAL OVERLAY
            if (o.modal) {
                $('<div class="bModal '+id+'"></div>')
                .css({'background-color': o.modalColor, 'height': '100%', 'left': 0, 'opacity': 0, 'position': 'fixed', 'top': 0, 'width': '100%', 'z-index': o.zIndex + popups})
                .each(function() {
                    if(o.appending) {
                        $(this).appendTo(o.appendTo);
                    }
                })
                .fadeTo(o.fadeSpeed, o.opacity);
            }
			
			// POPUP
            $popup
            	.data('bPopup', o).data('id',id)
				.css({ 'left': getLeft(!(!o.follow[0] && fixedHPos || fixedPosStyle)), 'position': o.positionStyle || 'absolute', 'top': getTop(!(!o.follow[1] && fixedVPos || fixedPosStyle)), 'z-index': o.zIndex + popups + 1 })
				.each(function() {
                	if(o.appending) {
                    	$(this).appendTo(o.appendTo);
                	}
            	})
            	.fadeIn(o.fadeSpeed, function() {
                	// Triggering the callback if set
                	triggerCall(callback);
                	// BINDING EVENTS
                	bindEvents();
            	});
		}
        function close() {
            if (o.modal) {
                $('.bModal.'+$popup.data('id'))
                .fadeTo(o.fadeSpeed, 0, function() {
                    $(this).remove();
                });
            }
            $popup.stop().fadeOut(o.fadeSpeed, function() {
                if (o.loadUrl) {
                    o.contentContainer.empty();
                }
				unbindEvents();
            });
            if (o.onClose) {
                setTimeout(function() {
                    triggerCall(o.onClose);
                }, o.fadeSpeed);
            }
			return false; // Prevent default
        }
        function bindEvents() {
            w.data('bPopup', popups);
			$popup.delegate('.' + o.closeClass, 'click.'+id, close);
            
            if (o.modalClose) {
                $('.bModal.'+id).css('cursor', 'pointer').bind('click', close);
            }

			// Temporary disabling scroll/resize events on devices with IOS6+
			// due to a bug where events are dropped after pinch to zoom
            if (!isIOS6X && (o.follow[0] || o.follow[1])) {
                w.bind('scroll.'+id, function() {
                	if(inside){
                    	$popup
                        	.stop()
                            .animate({ 'left': getLeft(o.follow[0] && !fixedPosStyle), 'top': getTop(o.follow[1] && !fixedPosStyle) }, o.followSpeed);
                     }  
            	}).bind('resize.'+id, function() {
                   	inside = insideWindow();
                   	if(inside){
                       cp = getCenterPosition($popup, o.amsl);
                       if (o.follow[0]) { hPos = (fixedHPos ? hPos : cp[0]);}
                       if (o.follow[1]) { vPos = (fixedVPos ? vPos : cp[1]); }
                      	$popup
                           	.stop()
                           	.each(function() {
                               	if(fixedPosStyle) {
                                	$(this).css({ 'left': hPos, 'top': vPos });
                               	}
                               	else {
                                   	$(this).animate({ 'left': getLeft(!fixedHPos), 'top': getTop(!fixedVPos) }, o.followSpeed);
                               	}
                           	});
                   	}
                });
            }
            if (o.escClose) {
                d.bind('keydown.'+id, function(e) {
                    if (e.which == 27) {  //escape
                        close();
                    }
                });
            }
        }
        function unbindEvents() {
            if (!o.scrollBar) {
                $('html').css('overflow', 'auto');
            }
            $popup.undelegate('.' + o.closeClass, 'click.'+id, close);
            $('.bModal.'+id).unbind('click');
            d.unbind('keydown.'+id);
            w.unbind('.'+id);
			w.data('bPopup', (w.data('bPopup')-1 > 0) ? w.data('bPopup')-1 : null);
            $popup.data('bPopup', null);
        }
		function getLeft(includeScroll){
			return includeScroll ? hPos + d.scrollLeft() : hPos;
		}
		function getTop(includeScroll){
			return includeScroll ? vPos + d.scrollTop() : vPos;
		}
		function triggerCall(func) {
			$.isFunction(func) && func.call($popup);
		}
       	function getCenterPosition(s, a) {
            var _x = ((windowWidth() - s.outerWidth(true)) / 2),
            _y = (((windowHeight()- s.outerHeight(true)) / 2) - a);
            return [_x,_y < 20 ? 20 : _y];
        }
        function insideWindow(){
            return windowHeight() > $popup.outerHeight(true)+20 && windowWidth() > $popup.outerWidth(true)+20;
        }
		function windowHeight(){
			return window.innerHeight || w.height();
		}
		function windowWidth(){
			return window.innerWidth || w.width();
		}
    };

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// DEFAULT VALUES
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
    $.fn.bPopup.defaults = {
          amsl: 			50
        , appending: 		true
        , appendTo: 		'body'
        , closeClass: 		'bClose'
        , content: 			'ajax'
        , contentContainer: false
        , escClose: 		true
        , fadeSpeed: 		250
        , follow: 			[true, true] // x, y
        , followSpeed: 		500
		, loadCallback: 	false
        , loadUrl: 			false
        , modal: 			true
        , modalClose: 		true
        , modalColor: 		'#000'
        , onClose: 			false
        , onOpen: 			false
        , opacity: 			0.7
        , position: 		['auto', 'auto'] // x, y,
        , positionStyle: 	'absolute'//type: absolute or fixed
        , scrollBar: 		true
        , zIndex: 			9997 // popup gets z-index 9999, modal overlay 9998
    };
})(jQuery);
