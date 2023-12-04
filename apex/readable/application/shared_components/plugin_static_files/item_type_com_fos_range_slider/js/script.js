/*global apex, $*/

window.FOS = window.FOS || {};
FOS.item = FOS.item || {};
FOS.item.rangeSlider = FOS.item.rangeSlider || {};

/**
 * Initialization function for the range slider page item.
 *
 * @param {object}      config                         The object holding the slider's configuration.
 * @param {number|date} config.minimumValue            Minimum value of the slider.
 * @param {number|date} config.maximumValue            Maximum value of the slider.
 * @param {string}      config.type                    Type of the slider, either number or date.
 * @param {number}      config.handles                 Number of handles.
 * @param {string}      config.itemName                Name of the page item (slider).
 * @param {number[]}    [config.value]                 The initial value of the slider.
 * @param {number}      [config.rangeLimit]            Limits the maximum distance between two handles.
 * @param {number}      [config.margin]                Sets the minimum distance between two handles (if flipRange is not set).
 * @param {boolean}     [config.tooltip]               Displays tooltips above the handles.
 * @param {string}      [config.retItems]              Page item names to bind to the slider (slider-values).
 * @param {boolean}     [config.connectBar]            Creates a connection between the handles. Dragging the bar drags both handles. If used with 1 handle, it creates the bar from slider's minValue.
 * @param {string}      [config.rangeColor]            Defines the color of the connect-bar.
 * @param {boolean}     [config.flipRange]             Specifies whether handle 1 can be dragged through handle 2 and vice-versa.
 * @param {string}      [config.orientation]           The orientation of the slider, either horizontal or vertical.
 * @param {object}      [config.numberFormat]          A wNumb format object to be used for number-formatting in the slider.
 * @param {boolean}     [config.keyboardSupport]       Enables movement of the handles with the keyboard.
 * @param {boolean}     [config.showTicks]             Displays the ticks under or next to the (in case of vertical) slider.
 * @param {string}      [config.direction]             Sets the directionality of the slider, either left-to-right or right-to-left.
 * @param {boolean}     [config.ticksStepped]          Specifies whether the ticks should only appear under the values which can be "stepped to" (i.e. set).
 * @param {number[]}    [config.tickPercentages]       Array of values (from 0 to 100) for the positions of the ticks relatively to the slider's range (e.g. [0, 50, 100] would place a tick at the min value, max value and at the center).
 * @param {number[]}    [config.tickValues]            Array of absolute values for the positions of the ticks (e.g. [0, 500, 1500, 1700]).
 * @param {boolean}     [config.clickOnTicks]          Enables / disables clicking on the ticks to set values.
 * @param {function}    [initFn]                       Javascript initialization function which allows you to override any settings before the slider is created
 */

FOS.item.rangeSlider.init = function (config, initJs) {

    // default values for the attributes that can be changed only through initJs
    config.keyboardSupport = true;
    config.direction = 'ltr';
    config.ticksStepped = true;
    config.clickOnTicks = true;
    config.tickPercentages = null;
    config.tickValues = null;

    if (initJs && typeof initJs == 'function') {
        initJs.call(this, config);
    }

    const CHANGE_EVENT = 'fos-rangeslider-change';

    let containerEl = document.getElementById(config.itemName);
    let slider;
    let type = config.type;
    let handleCount = config.handles;
    const isNumberType = type == 'number';
    const dateFormat = isNumberType ? null : config.dateFormat;
    const displayFormat = isNumberType ? null : config.displayFormat;
    const useDisplayFormat = isNumberType ? false : config.useDisplayFormat;
    let numberFormatCfg = isNumberType ? getNumberFormatCfg() : null;
    let chosenDateFormat = useDisplayFormat ? { to: formatDisplayDate, from: convertToTimestamp } : { to: formatDate, from: convertToTimestamp };
    let format = isNumberType ? wNumb(numberFormatCfg) : chosenDateFormat;
    let minValue = isNumberType ? parseFloat(config.minimumValue) : config.minimumValue;
    let maxValue = isNumberType ? parseFloat(config.maximumValue) : config.maximumValue;
    let minValueNum = isNumberType ? minValue : convertToTimestamp(config.minimumValue);
    let maxValueNum = isNumberType ? maxValue : convertToTimestamp(config.maximumValue);
    let value = getInitialValue();
    let boundToItems = [];
    let range = getRange();
    let ticksMode = Array.isArray(config.tickPercentages) ? 'positions' : (Array.isArray(config.tickValues) ? 'values' : 'count');
    let cfg = {
        range,
        keyboardSupport: config.keyboardSupport,
        margin: config.flipRange ? null : config.margin,
        orientation: config.orientation,
        step: getStep(),
        start: getHandleStartingPositions(),
        limit: config.flipRange ? null : ((config.rangeLimit && type != 'date' && handleCount == 2) ? parseInt(config.rangeLimit) : null),
        connect: config.connectBar && handleCount == 1 ? 'lower' : config.connectBar,
        direction: config.direction,
        behaviour: config.flipRange ? 'unconstrained-tap' : 'tap-drag',
        tooltips: config.tooltip ? handleCount == 1 ? [format] : [format, format] : null,
        format: format,
        pips: config.showTicks ? {
            stepped: config.ticksStepped,
            density: 2,
            format,
            values: ticksMode == 'positions' ? config.tickPercentages : (ticksMode == 'values' ? config.tickValues : config.ticks),
            mode: ticksMode
        } : false
    }

    slider = noUiSlider.create(containerEl, cfg);

    slider.on('set', values => {
        let oldValue = getReturnFormattedValue();
        let modified = false;

        // remove format
        values = values.map(format.from);

        modified = modifyValue(values);

        if (modified) {
            let val = getReturnFormattedValue();
            dispatchChange(oldValue, val);

            if (boundToItems.length) {
                let itemMin = boundToItems[0];
                let itemMax = boundToItems[1];
                let itemValue;
                let handleValue;

                if (itemMin) {
                    itemValue = itemMin.getValue();
                    handleValue = handleCount == 1 ? val : val[0];
                    if (itemValue != String(handleValue)) {
                        itemMin.setValue(handleValue);
                    }
                }
                if (itemMax) {
                    itemValue = itemMax.getValue();
                    handleValue = val[1];
                    if (itemValue != String(handleValue)) {
                        itemMax.setValue(handleValue);
                    }
                }
            }
        }
    });

    // set the background color of the range
    if (config.connectBar) {
        containerEl.querySelector('.noUi-connect').style.background = config.rangeColor;
    }

    // add click-functionality to the ticks if necessary
    if (config.showTicks && config.clickOnTicks) {
        let ticksContainer = containerEl.querySelector('.noUi-pips');
        let rangeDiff = maxValueNum - minValueNum;

        ticksContainer.addEventListener('click', e => {
            let box = ticksContainer.getBoundingClientRect();
            let perc;
            let dataVal = e.target.dataset.value;

            if (dataVal != null) {
                setValue(dataVal);
            }
            else {
                if (config.orientation == 'horizontal') {
                    let left = box.left;
                    let width = box.width;
                    let localX = Math.min(width, Math.max(0, e.clientX - left));
                    perc = localX / width;
                }
                else {
                    let top = box.top;
                    let height = box.height;
                    let localY = Math.min(height, Math.max(0, e.clientY - top));
                    perc = localY / height;
                }
                setValue(minValueNum + perc * rangeDiff);
            }
        });
    }

    // if there are items to return value(s) to...
    if (config.retItems) {
        let items = config.retItems.split(',');
        // only handle max as many fields as many handles there are
        if (items.length > handleCount) items.length = handleCount;
        for (let i = 0; i < items.length; i++) {
            setReturnItems(items[i], i);
        }
    }

    /**
    * Returns the range of the slider. This is necessary especially for the date slider with irregular steps (monthly, yearly)
    * as they contain different amount of millis so the percentage steps need to be counted.
    * 
    * @returns {object} Object with min, max values and possibly percentage values for monthly and yearly steps.
    */
    function getRange() {
        let range = {};
        let step = config.step;
        if (step == 'monthly' || step == 'yearly') {
            let min = moment(minValueNum);
            let max = moment(maxValueNum);
            let addPeriod = step == 'monthly' ? 'M' : 'y';
            let current = min.add(1, addPeriod);
            let mid = [];
            let percStep;

            while (current.isBefore(max)) {
                mid.push(current.toDate().getTime());
                current = current.add(1, addPeriod);
            }

            // if the step to the max is smaller than a month
            // then the max should be removed for the last accessible date
            if (current.isAfter(max)) {
                let last = mid.pop();
                if (last) {
                    maxValue = new Date(last).toJSON();
                    maxValueNum = last;
                }
                // if there was no mid points... (problem)... set the max to current... (?)
                else {
                    let d = current.toDate();
                    maxValue = d.toJSON();
                    maxValueNum = d.getTime();
                }
            }

            percStep = 100 / (mid.length + 1);

            // NOTE: What should we do when the last step is less than a month/year?
            // Should we disable setting that value? Should we modify the maxValue to the highest settable
            // value? Should we just leave it settable with a smaller step?
            if (percStep < 100) {
                mid.forEach((val, index) => {
                    let diff = (mid[index + 1] || maxValueNum) - val;
                    range[`${percStep * (index + 1)}%`] = [val, diff];
                });

                range.min = [minValueNum, mid[0] - minValueNum];
                range.max = [maxValueNum]
            }
            else {
                range.min = [minValueNum, maxValueNum - minValueNum],
                    range.max = [maxValueNum]
            }
        }
        else {
            range.min = minValueNum,
                range.max = maxValueNum
        }
        return range;
    }

    /**
     * Returns up the initial internal (always a number) value of the slider from the value provided in the config.
     * It tries to sanitize it as well in case of missing values, etc. This value is used in getRawValue.
     * 
     * @returns {number|number[]} Internal value.
     */
    function getInitialValue() {
        let value = config.value;
        if (handleCount == 1) {
            if (isNumberType) {
                value = value != null ? parseFloat(value) : minValueNum;
            }
            else {
                value = value != null ? convertToTimestamp(value) : minValueNum;
            }
        }
        else {
            if (isNumberType) {
                value[0] = value[0] != null ? parseFloat(value[0]) : minValueNum;
                value[1] = value[1] != null ? parseFloat(value[1]) : maxValueNum;
            }
            else {
                value[0] = value[0] != null ? convertToTimestamp(value[0]) : minValueNum;
                value[1] = value[1] != null ? convertToTimestamp(value[1]) : maxValueNum;
            }
        }
        return value;
    }

    /**
     * Modifies the internal (always number) value if it is not already the same value.
     * 
     * @param {number|number[]} newValue - The value which is possibly the new value
     * @returns {boolean} True or false based on whether the value was modified or not (i.e. was the same value).
     */
    function modifyValue(newValue) {
        if (handleCount == 1 && value != newValue[0]) {
            value = newValue[0];
            return true;
        }
        else if (handleCount == 2 && (value[0] != newValue[0] || value[1] != newValue[1])) {
            value = [...newValue];
            return true;
        }
        return false;
    }

    /**
     * Returns the wNumb number format config object, sets the required props and swaps decimal & thousand separators
     * if necessary.
     * 
     * @returns {object} wNumb config object.
     */
    function getNumberFormatCfg() {
        let cfg
        let nf = config.numberFormat;

        if (nf) {
            if (!('decimals' in nf))
                nf.decimals = 0;
            if (!('mark' in nf))
                nf.mark = nf.thousand == '.' ? ',' : '.';

            cfg = nf;
        }
        else {
            cfg = { decimals: 0 };
        }
        return cfg;
    }

    /**
     * Returns the starting positions (numbers) of the handles.
     * @returns {number|number[]} Starting position value(s).
     */
    function getHandleStartingPositions() {
        let result;
        if (handleCount == 1) {
            result = [isNumberType ? value : convertToTimestamp(value)];
        }
        else {
            result = isNumberType ? value.map(Number) : value.map(convertToTimestamp);
        }
        return result;
    }

    /**
     * Converts a date, string (number/date) or date-formatted string into a timestamp.
     * If it is not possible, uses the slider's minimum value for the timestamp.
     * 
     * @param {string|date} date - The date or string to be converted
     * @returns {number} Timestamp.
     */
    function convertToTimestamp(date) {
        let ts;
        if (typeof date == 'string') {
            if (date == Number(date)) {
                return Number(date);
            }
            date = parseDate(date);
        }
        ts = new Date(date).getTime();
        // invalid date's ts
        if (isNaN(ts)) {
            return minValueNum;
        }
        return ts;
    }

    /**
     * Formats the date to the config-set date-format mask.
     * 
     * @param {date} date - The date to be formatted.
     * @returns {string} Formatted date-string.
     */
    function formatDate(date) {
        return moment(date).format(dateFormat);
    }

    /**
     * Formats the date according to the display format override 
     * 
     * @param {date} date - The date to be formatted.
     * @returns {string} Formatted date-string.
     */
    function formatDisplayDate(date) {
        return moment(date).format(displayFormat);
    }

    /**
     * Parses a string to a native Date.
     * 
     * @param {string} str - The string to be parsed.
     * @returns {date} Native Date instance.
     */
    function parseDate(str) {
        var parsedDate;
        function checkParseSuccess(str, dateFormat) {
            parsedDate = moment(str, dateFormat);
            return parsedDate.isValid();
        }
        if (checkParseSuccess(str, moment.ISO_8601) || checkParseSuccess(str, dateFormat) || checkParseSuccess(str, displayFormat)) {
            return parsedDate.toDate();
        }
        apex.debug.error('Range Slider Error: Cannot parse date!!');
        return parsedDate.toDate();
    }

    /**
     * Calculates the steps of the slider.
     * 
     * @returns {number} The step size.
     */
    function getStep() {
        let step = config.step;
        if (isNumberType) {
            return Number(step);
        }
        else {
            if (step == 'monthly' || step == 'yearly') {
                return null;
            }
            else {
                const HOUR = 60 * 60 * 1000;
                let result;

                switch (step) {
                    case 'daily':
                        result = 24 * HOUR;
                        break;
                    case 'weekly':
                        result = 7 * 24 * HOUR;
                        break;
                }
                return result;
            }
        }
    }

    /**
     * Sanitizes the set value to be always in the format/type which we the slider uses.
     * 
     * @param {number|string|date} value - The value to be sanitized.
     * @returns {number|string} Sanitized (possibly formatted) value which is safe to be set to the slider's cmp.
     */
    function sanitizeValue(value) {
        // if it is a number, it is only one value
        if (typeof value == 'number') {
            // TODO: check whether for dates it works too
            return format.to(value);
        }
        // date needs to be converted to timestamp
        else if (value instanceof Date) {
            return convertToTimestamp(value);
        }
        // strings can be two values, etc. which can be numbers or dates...
        else if (typeof value == 'string') {
            let values = value.split(':');

            values = values.map(val => {
                let num = Number(val);
                // if it is a number
                if (num == val) {
                    return format.to(num);
                }
                else {
                    return val;
                }
            });
            return values.length == 1 ? values[0] : values;
        }
    }

    /**
     * Sets the value of the slider.
     * 
     * @param {number|string|date} value - The desired value(s).
     */
    function setValue(value) {
        slider.set(sanitizeValue(value));
    }

    /**
     * Formats the value to the "return format" (only keeps the decimal separator).
     * 
     * @returns {string[]|string} In case of two handles, an array is returned, otherwise a string
     */
    function getReturnFormattedValue() {
        if (isNumberType) {
            // replace only decimal separator and keep the decimal spaces
            let fmt = wNumb({ decimals: numberFormatCfg.decimals, mark: numberFormatCfg.mark });
            return Array.isArray(value) ? value.map(fmt.to) : fmt.to(value);
        }
        else {
            return Array.isArray(value) ? value.map(formatDate) : formatDate(value);
        }
    }

    /**
     * Returns the value of the slider as a string. In case of two handles, the two values are concatenated
     * with a colon.
     * 
     * @returns {string} The value of the slider.
     */
    function getValue() {
        let value = getReturnFormattedValue();
        return Array.isArray(value) ? value.join(':') : value;
    }

    /**
     * Returns the raw unformatted internal value of the slider.
     * 
     * @returns {number[]|number} The raw value, in case of two handles it is an array. 
     */
    function getRawValue() {
        return value;
    }

    /**
     * Sets up the binding between the slider/handle's value and the page item.
     * 
     * @param {string} itemName - The name of the page item to bind to.
     * @param {number} index - Index of the handle, either 0 or 1 (lower/upper).
     */
    function setReturnItems(itemName, index) {
        let item = apex.item(itemName);
        let value = getReturnFormattedValue();

        boundToItems[index] = item;

        // change the value based on the bound page items or set them to the value of the slider
        if (item.getValue() != '') {
            itemChange();
        }
        else {
            item.setValue(Array.isArray(value) ? value[Math.min(index, value.length - 1)] : value);
        }

        // apex item on change
        $(item.node).on('change', itemChange);

        function itemChange() {
            let itemValue = item.getValue();
            let sliderValue = getReturnFormattedValue();
            sliderValue = handleCount == 1 ? sliderValue : sliderValue[index];
            let iv = isNumberType ? format.from(itemValue) : convertToTimestamp(itemValue);
            if (iv > maxValueNum) {
                item.setValue(isNumberType ? maxValueNum : format.to(maxValue));
                return;
            }
            else if (iv < minValueNum) {
                item.setValue(isNumberType ? minValueNum : format.to(minValue));
                return;
            }

            if (itemValue != String(sliderValue)) {
                let val = sanitizeValue(itemValue);
                !index ? slider.set([val, null]) : slider.set([null, val]);
            }
        }
    }

    /**
     * Dispatches the change event to APEX.
     * 
     * @param {number|number[]|string|string[]} oldValue - Return-formatted oldValue.
     * @param {number|number[]|string|string[]} newValue - Return-formatted newValue.
     */
    function dispatchChange(oldValue, newValue) {
        apex.event.trigger(`#${config.itemName}`, CHANGE_EVENT, { oldValue, newValue });
    }

    // plugin's public interface
    apex.item.create(config.itemName, {
        setValue,

        getValue,

        getRawValue,

        disable() {
            containerEl.setAttribute('disabled', true);
        },

        enable() {
            containerEl.removeAttribute('disabled');
        },

        getSliderCmp() {
            return slider;
        }
    });
};