/* jQuery Access Keys Plugin Beta 1 - A jQuery plugin to automatically assign access keys
 * Author: Jamie Thompson (jamie_at_themagictorch_d0t_org) 
 * Website: http://jamazon.co.uk
 * 
 * Copyright (c) 2008 Jamie Thompson
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

$.fn.accessKeys = function(){
	
	var keys = new Array(0);
	
	var find = function(ary, element){
	    for(var i=0; i<ary.length; i++){
	        if(ary[i] == element){
	            return true;
	        };
	    };
	    return false;
	};
	
	$(this).each(function(i){
		
		for (var j=0; j < $(this).text().length; j++){
			
			var char = $(this).text().charAt(j);
					
			if(!find(keys,char.toLowerCase()) && char.match(/[A-Za-z_0-9]/)){
				regexp = new RegExp(char,"i");
				$(this).html( $(this).html().replace(regexp,'<u>'+char+'</u>') );
				$(this).attr( 'accesskey', char.toLowerCase() );
				keys[i] = char.toLowerCase();
				break;
			};
			
		};
	});
	
};

