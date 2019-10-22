function handleRecurrenceTypeChange() {
    var type = $('#issue_recurrence_type').val();
    var $form = $('#meeting_form');
    $form.find('.recurrence-options').hide().find('select, input').attr('disabled', true);
    if (type != '') {
        $form.find('.recurrence-options.' + type).show().find('select, input').removeAttr('disabled');
        if ((type == 'monthly') || (type == 'yearly')) {
            handleRecurrenceByChange($form.find('.recurrence-options.' + type + ' input[type=radio]:checked').closest('span'));
        }
        var $interval = $('#recurrence_interval');
        $interval.text($interval.data(type));
    }
    $('#recurrence_options').toggle(type != '').find('select').attr('disabled', type == '');
}
function handleRecurrenceEndChange() {
    var end = $('#issue_recurrence_end').val();
    var $options = $('#recurrence_options');
    $options.find('.end-options').hide().find('select, input').attr('disabled', true);
    if (end != '') {
        $options.find('.end-' + end).show().find('select, input').removeAttr('disabled');
    }
}
function handleRecurrenceByChange($span) {
    if ($span.find('input[type=radio]').prop('checked')) {
        $span.find('select').removeAttr('disabled');
        $span.siblings('span').find('select').attr('disabled', true);
    }
}
