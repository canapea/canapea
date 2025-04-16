(view
  (!doctype html)
  (html 
    lang "en"
    (head
      (meta
        charset "utf-8"
        app/config/backend "/api"
      )
      (title "Testpage")
    )
    (body
      on-domcontentloaded (boot event)
      (x-app
        (span
          slot "greeting"
          "Hello, World!"
        )
      )
    )
    (script
      type "importmap"
    """
    {
      "imports": {
        "weave": "./cdn/weave.js"
      }
    }
    """
    )
    (script
    """
    "use strict";
  
    function boot(ev) {
      console.log("boot", ev, this, self);
    }
  
    """)
  )
)

(component "x-app"
  (from "weave" import [])
  (style
  """
  b { color: red; }
  """
  )
  (require _Store)
  (render [_props _state]
    (b
      (slot name "greeting")
    )
  )
)