var orig_contextMenuAddSelection = contextMenuAddSelection;

contextMenuAddSelection = function(tr) {
    orig_contextMenuAddSelection.apply(this, arguments);

    var $cal = tr.closest('table.cal');
    if ($cal.length > 0) {
        var $td = tr.closest('td');
        var $tr = $td.closest('tr');
        var $form = $cal.closest('form');
        var rowIndex = Array.prototype.indexOf.call($tr.parent().children('tr'), $tr[0]);
        var columnIndex = Array.prototype.indexOf.call($td.parent().children('td'), $td[0]);
        var date = new Date($form.data('startdt').valueOf());
        date.setDate(date.getDate() + (rowIndex * 7 + (columnIndex - 1)));
        var month = date.getMonth() + 1;
        var day = date.getDate();
        var $date = $form.find('input[name="date"]');
        if ($date.length == 0) {
            $date = $('<input>', { type: 'hidden', name: 'date' });
            $form.append($date);
        }
        $date.val(date.getFullYear() + '-' + (month > 9 ? '' : '0') + month + '-' + (day > 9 ? '' : '0') + day);
    }
}
