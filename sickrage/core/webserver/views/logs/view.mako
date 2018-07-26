<%inherit file="../layouts/main.mako"/>
<%!
    import sickrage
%>
<%block name="content">
    <div class="row">
        <div class="col">
            <div class="card mt-3 mb-3">
                <div class="card-header">
                    <h3 class="float-md-left">${title}</h3>
                    <div class="d-inline-flex float-md-right">
                        <label class="m-1">
                            <select name="minLevel" id="minLevel"
                                    class="form-control form-control-inline input-sm">
                                <% levels = [x for x in sickrage.app.log.logLevels.keys() if any([sickrage.app.config.debug and x in ['DEBUG','DB'], x not in ['DEBUG','DB']])]%>
                                <% levels.sort(lambda x,y: cmp(sickrage.app.log.logLevels[x], sickrage.app.log.logLevels[y])) %>
                                % for level in levels:
                                    <option value="${sickrage.app.log.logLevels[level]}" ${('', 'selected')[minLevel == sickrage.app.log.logLevels[level]]}>${level.title()}</option>
                                % endfor
                            </select>
                        </label>

                        <label class="m-1">
                            <select name="logFilter" id="logFilter" class="form-control form-control-inline input-sm">
                                % for logNameFilter in sorted(logNameFilters):
                                    <option value="${logNameFilter}" ${('', 'selected')[logFilter == logNameFilter]}>${logNameFilters[logNameFilter]}</option>
                                % endfor
                            </select>
                        </label>

                        <label class="m-1">
                            <input type="text" name="logSearch" placeholder="${_('clear to reset')}" id="logSearch"
                                   value="${('', logSearch)[bool(logSearch)]}"
                                   class="form-control form-control-inline input-sm"/>
                        </label>
                    </div>
                </div>
                <div class="card-body">
                    <div class="align-left" style="white-space: pre-line;">
                        ${logLines}
                    </div>
                </div>
            </div>
        </div>
    </div>
</%block>
