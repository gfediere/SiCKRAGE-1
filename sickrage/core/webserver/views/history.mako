<%inherit file="./layouts/main.mako"/>
<%!
    import os.path
    import datetime
    import re
    import time

    import sickrage
    from sickrage.core.helpers import srdatetime
    from sickrage.core.common import SKIPPED, WANTED, UNAIRED, ARCHIVED, IGNORED, SNATCHED, SNATCHED_PROPER, SNATCHED_BEST, FAILED, DOWNLOADED, SUBTITLED
    from sickrage.core.common import Quality, statusStrings, Overview
    from sickrage.core.tv.show.history import History
%>
<%block name="content">
    <%namespace file="./includes/quality_defaults.mako" import="renderQualityPill"/>
    <div class="row">
        <div class="col-md-10 mx-auto">
            <div class="card mt-3 mb-3">
                <div class="card-header">
                    <h3 class="float-md-left">${title}</h3>
                    <div class="float-md-right">
                        <div class="form-inline">
                            <select name="history_limit" id="history_limit" class="form-control mr-sm-2">
                                <option value="10" ${('', 'selected')[limit == 10]}>10</option>
                                <option value="25" ${('', 'selected')[limit == 25]}>25</option>
                                <option value="50" ${('', 'selected')[limit == 50]}>50</option>
                                <option value="100" ${('', 'selected')[limit == 100]}>100</option>
                                <option value="250" ${('', 'selected')[limit == 250]}>250</option>
                                <option value="500" ${('', 'selected')[limit == 500]}>500</option>
                                <option value="750" ${('', 'selected')[limit == 750]}>750</option>
                                <option value="1000" ${('', 'selected')[limit == 1000]}>1000</option>
                                <option value="0"   ${('', 'selected')[limit == 0  ]}>${_('All')}</option>
                            </select>

                            <select name="HistoryLayout" class="form-control"
                                    onchange="location = this.options[this.selectedIndex].value;">
                                <option value="${srWebRoot}/setHistoryLayout/?layout=compact"  ${('', 'selected')[sickrage.app.config.history_layout == 'compact']}>
                                    ${_('Compact')}
                                </option>
                                <option value="${srWebRoot}/setHistoryLayout/?layout=detailed" ${('', 'selected')[sickrage.app.config.history_layout == 'detailed']}>
                                    ${_('Detailed')}
                                </option>
                            </select>
                        </div>
                    </div>

                </div>
                <div class="card-body">
                    % if sickrage.app.config.history_layout == "detailed":
                        <table id="historyTable" class="table">
                            <thead>
                            <tr>
                                <th class="text-nowrap">${_('Time')}</th>
                                <th>${_('Episode')}</th>
                                <th>${_('Action')}</th>
                                <th>${_('Provider')}</th>
                                <th>${_('Quality')}</th>
                            </tr>
                            </thead>

                            <tfoot>
                            <tr>
                                <th class="nowrap" colspan="5">&nbsp;</th>
                            </tr>
                            </tfoot>

                            <tbody>
                                % for hItem in historyResults:
                                    <% curStatus, curQuality = Quality.splitCompositeStatus(int(hItem["action"])) %>
                                    <tr>
                                        <td align="center">
                                            <% airDate = srdatetime.srDateTime(datetime.datetime.strptime(str(hItem["date"]), History.date_format)).srfdatetime(show_seconds=True) %>
                                            <% isoDate = datetime.datetime.strptime(str(hItem["date"]), History.date_format).isoformat() %>
                                            <time datetime="${isoDate}" class="date">${airDate}</time>
                                        </td>
                                        <td class="text-center tvShow">
                                            <a href="${srWebRoot}/home/displayShow?show=${hItem["show_id"]}#S${hItem["season"]}E${hItem["episode"]}">
                                                ${hItem["show_name"]}
                                                - ${"S{:02d}".format(int(hItem["season"]))}${"E{:02d}".format(int(hItem["episode"]))} ${('', '<span class="badge badge-success">Proper</span>')["proper" in hItem["resource"].lower() or "repack" in hItem["resource"].lower()]}
                                            </a>
                                        </td>
                                        <td align="center" ${('', 'class="subtitles_column"')[curStatus == SUBTITLED]}>
                                            % if curStatus == SUBTITLED:
                                                <i class="sickrage-flags sickrage-flag-${hItem['resource']}"></i>
                                            % endif
                                            <span style="cursor: help; vertical-align:middle;"
                                                  title="${os.path.basename(hItem['resource'])}">${statusStrings[curStatus]}</span>
                                        </td>
                                        <td align="center">
                                            % if curStatus in [DOWNLOADED, ARCHIVED]:
                                                % if hItem["provider"] != "-1":
                                                    <span style="vertical-align:middle;"><i>${hItem["provider"]}</i></span>
                                                % endif
                                            % else:
                                                % if hItem["provider"] > 0:
                                                    % if curStatus in [SNATCHED, FAILED]:
                                                        % if hItem["provider"].lower() in sickrage.app.search_providers.all():
                                                        <% provider = sickrage.app.search_providers.all()[hItem["provider"].lower()] %>
                                                            <i class="sickrage-providers sickrage-providers-${provider.id}"
                                                               style="vertical-align:middle;"></i><span
                                                                style="vertical-align:middle;">${provider.name}</span>
                                                        % else:
                                                            <span style="vertical-align:middle;">${hItem["provider"]}</span>
                                                        % endif
                                                    % else:
                                                        <i class="sickrage-subtitles sickrage-subtitles-${hItem['provider']}"
                                                           style="vertical-align:middle;"></i>
                                                        <span style="vertical-align:middle;">${hItem["provider"].capitalize()}</span>
                                                    % endif
                                                % endif
                                            % endif
                                        </td>
                                        <td style="display: none;">${curQuality}</td>
                                        <td align="center">${renderQualityPill(curQuality)}</td>
                                    </tr>
                                % endfor
                            </tbody>
                        </table>
                    % else:
                        <table id="historyTable" class="table pre-scrollable">
                            <thead>
                            <tr>
                                <th class="nowrap">${_('Time')}</th>
                                <th>${_('Episode')}</th>
                                <th>${_('Snatched')}</th>
                                <th>${_('Downloaded')}</th>
                                % if sickrage.app.config.use_subtitles:
                                    <th>${_('Subtitled')}</th>
                                % endif
                                <th>${_('Quality')}</th>
                            </tr>
                            </thead>

                            <tfoot>
                            <tr>
                                <th class="nowrap" colspan="6">&nbsp;</th>
                            </tr>
                            </tfoot>

                            <tbody>
                                % for hItem in compactResults:
                                    <tr>
                                        <td align="center">
                                            <% airDate = srdatetime.srDateTime(datetime.datetime.strptime(str(hItem["actions"][0]["time"]), History.date_format)).srfdatetime(show_seconds=True) %>
                                            <% isoDate = datetime.datetime.strptime(str(hItem["actions"][0]["time"]), History.date_format).isoformat() %>
                                            <time datetime="${isoDate}" class="date">${airDate}</time>
                                        </td>
                                        <td class="tvShow" width="25%">
                                                            <span>
                                                                <a href="${srWebRoot}/home/displayShow?show=${hItem["show_id"]}#season-${hItem["season"]}">
                                                                    ${hItem["show_name"]}
                                                                    - ${"S{:02d}".format(int(hItem["season"]))}${"E{:02d}".format(int(hItem["episode"]))}${('', ' <span class="badge badge-success">Proper</span>')['proper' in hItem["resource"].lower() or 'repack' in hItem["resource"].lower()]}
                                                                </a>
                                                            </span>
                                        </td>
                                        <td align="center"
                                            data-provider="${str(sorted(hItem["actions"])[0]["provider"])}">
                                            % for action in sorted(hItem["actions"]):
                                                <% curStatus, curQuality = Quality.splitCompositeStatus(int(action["action"])) %>
                                                % if curStatus in [SNATCHED, FAILED]:
                                                    % if action["provider"].lower() in sickrage.app.search_providers.all():
                                                    <% provider = sickrage.app.search_providers.all()[action["provider"].lower()] %>
                                                        <i class="sickrage-providers sickrage-providers-${provider.id}"
                                                           title="${provider.name}: ${os.path.basename(action["resource"])}"
                                                           style="vertical-align:middle;cursor: help;"></i>
                                                    % else:
                                                        <i class="sickrage-providers sickrage-providers-missing"
                                                           style="vertical-align:middle;"
                                                           title="${_('missing provider')}"></i>
                                                    % endif
                                                % endif
                                            % endfor
                                        </td>
                                        <td align="center">
                                            % for action in sorted(hItem["actions"]):
                                                <% curStatus, curQuality = Quality.splitCompositeStatus(int(action["action"])) %>
                                                % if curStatus in [DOWNLOADED, ARCHIVED]:
                                                    % if action["provider"] != "-1":
                                                        <span style="cursor: help;"
                                                              title="${os.path.basename(action["resource"])}"><i>${action["provider"]}</i></span>
                                                    % else:
                                                        <span style="cursor: help;"
                                                              title="${os.path.basename(action["resource"])}"></span>
                                                    % endif
                                                % endif
                                            % endfor
                                        </td>
                                        % if sickrage.app.config.use_subtitles:
                                            <td align="center">
                                                % for action in sorted(hItem["actions"]):
                                                    <% curStatus, curQuality = Quality.splitCompositeStatus(int(action["action"])) %>
                                                    % if curStatus == SUBTITLED:
                                                        <i class="sickrage-subtitles sickrage-subtitles-${action['provider']}"
                                                           style="vertical-align:middle;"
                                                           title="${action["provider"].capitalize()}: ${os.path.basename(action["resource"])}"></i>
                                                        <span style="vertical-align:middle;"> / </span>
                                                        <i class="sickrage-flags sickrage-flag-${action['resource']}"></i>
                                                        &nbsp;
                                                    % endif
                                                % endfor
                                            </td>
                                        % endif
                                        <td align="center" width="14%" data-quality="${curQuality}">
                                            ${renderQualityPill(curQuality)}
                                        </td>
                                    </tr>
                                % endfor
                            </tbody>
                        </table>
                    % endif
                </div>
            </div>
        </div>
    </div>
</%block>
