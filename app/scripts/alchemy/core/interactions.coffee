# Alchemy.js is a graph drawing application for the web.
# Copyright (C) 2014  GraphAlchemist, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

alchemy.interactions =
    edgeClick: (d) ->
        vis = alchemy.vis
        vis.selectAll '.edge'
            .classed 'highlight': false
        d3.select "[source-target='#{d.id}']"
            .classed {'highlight': true, 'selected': true}
        d3.event.stopPropagation()
        if typeof alchemy.conf.edgeClick? is 'function'
            alchemy.conf.edgeClick()

    nodeMouseOver: (n) ->
        node = alchemy._nodes[n.id]
        # node.setStyles {
        #     "fill": "#FFFFFF"
        #     "stroke-width": "3px"
        #     "fill-opacity": ".8"
        # }

        # temporary fix until Node#setStyles() is working
        alchemy.vis.select "#node-#{n.id} circle"
               .style "fill", "#FFFFFF"

        if alchemy.conf.nodeMouseOver?
            if typeof alchemy.conf.nodeMouseOver is 'function'
                alchemy.conf.nodeMouseOver(node)
            else if typeof alchemy.conf.nodeMouseOver is ('number' or 'string')
                # the user provided an integer or string to be used
                # as a data lookup key on the node in the graph json
                node.properties[alchemy.conf.nodeMouseOver]
        else
            null

    nodeMouseOut: (n) ->
        # temporary fix until Node#setStyles() is working
        alchemy.vis.select "#node-#{n.id} circle"
               .style "fill", (d)-> 
                    nodeType = alchemy._nodes[d.id]["_nodeType"]
                    nodeStyles = alchemy.conf.nodeStyle
                    typeStyle = nodeStyles[nodeType]
                    if typeStyle is not undefined
                        typeStyle["color"]()
                    else 
                        nodeStyles["all"]["color"]()

        if alchemy.conf.nodeMouseOut? and typeof alchemy.conf.nodeMouseOut is 'function'
            alchemy.conf.nodeMouseOut(n)
        else
            null

    nodeClick: (c) ->
        d3.event.stopPropagation()
        # select the correct nodes
        if !alchemy.vis.select("#node-#{c.id}").empty()
            selected = alchemy.vis.select("#node-#{c.id}").classed('selected')
            alchemy.vis.select("#node-#{c.id}").classed('selected', !selected)

        if typeof alchemy.conf.nodeClick is 'function'
            alchemy.conf.nodeClick(c)
            return

    zoom: (extent) ->
                if not @._zoomBehavior?
                    @._zoomBehavior = d3.behavior.zoom()
                @._zoomBehavior.scaleExtent extent
                                .on "zoom", ->
                                    alchemy.vis.attr("transform", "translate(#{ d3.event.translate }) 
                                                                scale(#{ d3.event.scale })" )
                                    
    clickZoom:  (direction) ->
                    [x, y, scale] = alchemy.vis
                                           .attr("transform")
                                           .match(/(-*\d+\.*\d*)/g)
                                           .map( (a) -> return parseFloat(a) )

                    alchemy.vis
                        .attr "transform", ->
                            if direction is "in"
                                scale += 0.2 if scale < alchemy.conf.scaleExtent[1]
                                return "translate(#{x},#{y}) scale(#{ scale })"
                            else if direction is "out"
                                scale -= 0.2 if scale > alchemy.conf.scaleExtent[0]
                                return "translate(#{x},#{y}) scale(#{ scale })"
                            else if direction is "reset"
                                return "translate(0,0) scale(1)"
                            else
                                console.log 'error'
                    if not @._zoomBehavior?
                        @._zoomBehavior = d3.behavior.zoom()
                    @._zoomBehavior.scale(scale)
                                   .translate([x,y])

    toggleControlDash: () ->
        #toggle off-canvas class on click
        offCanvas = d3.select("#control-dash-wrapper").classed("off-canvas") or d3.select("#control-dash-wrapper").classed("initial")
        d3.select("#control-dash-wrapper").classed("off-canvas": !offCanvas, "initial": false, "on-canvas": offCanvas)

    nodeDragStarted: (d, i) ->
        d3.event.sourceEvent.stopPropagation()
        d3.select(this).classed("dragging", true)
        d.fixed = true

    nodeDragged: (d, i) ->
        d.x += d3.event.dx
        d.y += d3.event.dy
        d.px += d3.event.dx
        d.py += d3.event.dy

        node = d3.select(this)
        node.attr("transform", "translate(#{d.x}, #{d.y})")
        edgeIDs = alchemy._nodes[d.id]._adjacentEdges
        for id in edgeIDs
            selection = d3.select("#edge-#{id}")
            alchemy._drawEdges.updateEdge(selection.data()[0])

    nodeDragended: (d, i) ->
        d3.select(this).classed "dragging": false
        if !alchemy.conf.forceLocked  #alchemy.configuration for forceLocked
            alchemy.force.start() #restarts force on drag

    deselectAll: () ->
        # this function is also fired at the end of a drag, do nothing if this
        if d3.event?.defaultPrevented then return
        alchemy.vis.selectAll('.node, .edge')
            .classed('selected highlight', false)

        d3.select('.alchemy svg').classed({'highlight-active':false})

        if alchemy.conf.showEditor is true
            alchemy.modifyElements.nodeEditorClear()

        alchemy.vis.selectAll('line.edge')
            .classed('highlighted connected unconnected', false)
        alchemy.vis.selectAll('g.node,circle,text')
            .classed('selected unselected neighbor unconnected connecting', false)
        # call user-specified deselect function if specified
        if alchemy.conf.deselectAll and typeof(alchemy.conf.deselectAll is 'function')
            alchemy.conf.deselectAll()
