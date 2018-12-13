using System.Collections;
//using System.Collections.Generic;
using UnityEngine.Networking;
using UnityEngine;

public class camera_logic : NetworkBehaviour {

    public Camera cam;

	// Use this for initialization
	void Start () {


		
	}
	
	// Update is called once per frame
	void Update () {

        if (!isLocalPlayer)
        {
            cam.enabled = false;
            return;
        }
		
	}
}
