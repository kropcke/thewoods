// (c) Copyright HutongGames, LLC 2010-2016. All rights reserved.

using UnityEngine;

namespace HutongGames.PlayMaker.Actions
{
	[ActionCategory(ActionCategory.Animator)]
	[Tooltip("Sets the value of a int parameter")]
	public class SetAnimatorInt : FsmStateActionAnimatorBase
	{
		[RequiredField]
		[CheckForComponent(typeof(Animator))]
		[Tooltip("The target.")]
		public FsmOwnerDefault gameObject;

        [RequiredField]
        [UIHint(UIHint.AnimatorInt)]
		[Tooltip("The animator parameter")]
		public FsmString parameter;
		
		[Tooltip("The Int value to assign to the animator parameter")]
		public FsmInt Value;


		private Animator _animator;
		private int _paramID;
		
		public override void Reset()
		{
			base.Reset();
			gameObject = null;
			parameter = null;
			Value = null;
		}

		public override void OnEnter()
		{
			// get the animator component
			var go = Fsm.GetOwnerDefaultTarget(gameObject);
			
			if (go==null)
			{
				Finish();
				return;
			}
			
			_animator = go.GetComponent<Animator>();
			
			if (_animator==null)
			{
				Finish();
				return;
			}

			// get hash from the param for efficiency:
			_paramID = Animator.StringToHash(parameter.Value);
			
			SetParameter();
			
			if (!everyFrame) 
			{
				Finish();
			}
		}
	
		public override void OnActionUpdate ()
		{
			SetParameter();
		}
		
		void SetParameter()
		{		
			if (_animator!=null)
			{
				_animator.SetInteger(_paramID,Value.Value) ;			
			}
		}
	}
}