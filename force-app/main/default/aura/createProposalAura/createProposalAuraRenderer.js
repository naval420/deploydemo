({

rerender : function(cmp, helper) {
  this.superRerender();
 var pageRef = cmp.get("v.pageReference");
        var state = pageRef.state; // state holds any query params
        var base64Context = state.inContextOfRef;
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }
        var addressableContext = JSON.parse(window.atob(base64Context));
      var childLWCComponent = cmp.find("childCmp");
      if (childLWCComponent) {
            childLWCComponent.lwcOnload(addressableContext.attributes.recordId);
        } else {
            console.error("Child component not found");
        }
}

})